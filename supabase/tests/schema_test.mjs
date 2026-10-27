import {PGlite} from '@electric-sql/pglite';
import {readFile} from 'node:fs/promises';
import assert from 'node:assert/strict';

// Real PostgreSQL in an isolated in-memory database, never the live project.
const db=new PGlite();
await db.exec(`
  create role anon; create role authenticated; create role service_role bypassrls;
  create schema auth; create schema storage;
  create table auth.users(id uuid primary key,email text,raw_user_meta_data jsonb);
  create table storage.buckets(id text primary key,name text,public boolean,file_size_limit bigint,allowed_mime_types text[]);
  create table public.profiles(id uuid primary key,username text,display_name text,bio text,created_at timestamptz);
  create table public.experiences(id uuid,author_id uuid,is_anonymous boolean,category text,subject_name text,title text,body text,created_at timestamptz);
  create table public.posts(id uuid,author_id uuid,is_anonymous boolean,caption text,created_at timestamptz);
  create table public.experience_comments(id uuid,experience_id uuid,author_id uuid,body text,created_at timestamptz);
  create table public.experience_reactions(user_id uuid,experience_id uuid,reaction text);
  create table public.post_reactions(user_id uuid,post_id uuid,reaction text);
  create table public.experience_comment_reactions(user_id uuid,comment_id uuid,reaction text);
`);
const schema=await readFile(new URL('../sql/defame_setup.sql',import.meta.url),'utf8');
await db.exec(schema);
const user='10000000-0000-4000-8000-000000000001';
const other='10000000-0000-4000-8000-000000000002';
await db.query(`insert into auth.users(id,raw_user_meta_data) values($1,'{"username":"David"}'),($2,'{"username":"Alex"}')`,[user,other]);
await assert.rejects(()=>db.query(`insert into auth.users(id,raw_user_meta_data) values(gen_random_uuid(),'{"username":"dAvId"}')`),/duplicate key/);
await assert.rejects(()=>db.query(`update public.df_accounts set username='david' where id=$1`,[other]),/duplicate key/);
// An underscore is a legal username character, not an availability wildcard.
await db.query(`insert into auth.users(id,raw_user_meta_data) values(gen_random_uuid(),'{"username":"DavidXP"}')`);
assert.equal((await db.query(`select id from public.df_accounts where username ilike $1`,['David\\_P'])).rows.length,0);
await db.query(`insert into auth.users(id,raw_user_meta_data) values(gen_random_uuid(),'{"username":"David_P"}')`);
assert.equal((await db.query(`select id from public.df_accounts where username ilike $1`,['david\\_p'])).rows.length,1);
await db.query(`insert into public.df_posts(author_id,request_id,title,body,category,is_anonymous,moderation_status,expires_at)
values($1,'public','Public story','Firsthand story','Dating',false,'approved',null),
($1,'anon','Anonymous story','Firsthand story','Dating',true,'approved',now()+interval '1 hour'),
($1,'expired','Expired story','Firsthand story','Dating',true,'approved',now()-interval '1 second')`,[user]);
const feed=async(author=null,mine=false)=> (await db.query(`select * from public.df_feed($1,'','Recent',$2,null,$3,0)`,[user,author,mine])).rows;
assert.equal((await feed()).length,2);
assert.equal((await feed(user)).length,1,'Public profiles must omit anonymous posts, even for the owner.');
assert.equal((await feed(null,true)).length,3,'Private manager retains expired/anonymous submissions.');
await db.query(`insert into public.df_blocks(user_id,blocked_id) values($1,$2)`,[other,user]);
assert.equal((await db.query(`select * from public.df_feed($1,'','Recent',null,null,false,0)`,[other])).rows.length,0);
const permissions=(await db.query(`select
  has_table_privilege('anon','public.df_accounts','select') as account_read,
  has_table_privilege('authenticated','public.df_posts','select') as posts_read,
  has_function_privilege('authenticated','public.df_complete_verification(uuid,text,boolean,boolean)','execute') as forge_verification,
  has_function_privilege('anon','public.df_publish(jsonb,uuid)','execute') as bypass_moderation`)).rows[0];
assert.deepEqual(permissions,{account_read:false,posts_read:false,forge_verification:false,bypass_moderation:false});
const session=(await db.query(`insert into public.df_verifications(user_id,provider_ref) values($1,'provider-ref') returning id`,[user])).rows[0].id;
assert.equal((await db.query(`select public.df_complete_verification($1,'wrong-ref',true,true) as ok`,[session])).rows[0].ok,false);
assert.equal((await db.query(`select public.df_complete_verification($1,'provider-ref',true,true) as ok`,[session])).rows[0].ok,true);
assert.equal((await db.query(`select public.df_complete_verification($1,'provider-ref',false,false) as ok`,[session])).rows[0].ok,false);
const payload={author_id:user,request_id:'retry',title:'Retry story',body:'A real firsthand story',category:'Other',kind:'post',
  is_anonymous:true,moderation_status:'pending',created_at:new Date().toISOString(),expires_at:new Date(Date.now()+7200000).toISOString()};
const publish=async()=> (await db.query(`select (public.df_publish($1::jsonb,null)).id`,[JSON.stringify(payload)])).rows[0].id;
assert.equal(await publish(),await publish(),'Submission retries must not duplicate a story.');
const limits=[];for(let i=0;i<3;i++) limits.push((await db.query(`select public.df_consume_limit($1,'test',2) as allowed`,[user])).rows[0].allowed);
assert.deepEqual(limits,[true,true,false]);
console.log('PASS: schema install, unique usernames, public/anonymous visibility, expiration, blocks, client access, verification binding/replay, idempotency, rate limits.');
await db.close();
