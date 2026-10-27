import('./schema_test.mjs').catch(error=>{
  console.error(`FAIL: ${error.message} (${error.code??'test failure'})`);
  process.exit(1);
});
