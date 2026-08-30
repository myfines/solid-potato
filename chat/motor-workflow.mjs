const defaultOrderNumber='6ES7 214-1BG40-0XB0';

export async function buildMotorProject({client, name, projectDirectory, backupPath, deviceName='PLC_1', orderNumber=defaultOrderNumber, call}) {
  const stepResults=[];
  const run=async(tool, args)=>{
    const result=await call(tool,args);
    if(result?.isError) throw new Error(`${tool} failed: ${JSON.stringify(result.structuredContent||result.content||result)}`);
    stepResults.push({tool,success:true});
    return result;
  };
  const session=await run('projects_get_session_info',{});
  const sessionText=JSON.stringify(session);
  if(!/hasOpenProject[^a-zA-Z]+true/.test(sessionText)) {
    await run('projects_create',{name,path:projectDirectory});
    await run('projects_open',{path:`${projectDirectory}\\${name}.ap20`});
  } else if(!sessionText.includes(name)) {
    throw new Error('TIA 当前已有其他工程打开；为保护用户工程，已停止。请关闭当前工程后再创建隔离项目，或明确指定复用当前工程。');
  }
  await run('devices_create',{deviceName,orderNumber,dryRun:false});
  const tags=[
    ['Start_Button','%I0.0'],['Stop_Button','%I0.1'],['Emergency_Stop','%I0.2'],['Reset_Button','%I0.3'],
    ['Motor_Run','%Q0.0'],['Run_Lamp','%Q0.1'],['Fault_Lamp','%Q0.2']
  ];
  for(const [tagName,logicalAddress] of tags) await run('tags_create',{deviceName,tagTableName:'Default tag table',tagName,dataType:'Bool',logicalAddress});
  await run('projects_save',{});
  if(backupPath) await call('tia_backup_project',{project:`${projectDirectory}\\${name}.ap20`,backupPath});
  const lad=await call('tia_build_lad',{projectMatch:name,deviceName,name:'Main',blockType:'OB',blockNumber:1,networks:[{title:'Motor starter',rungs:[{contacts:[{addr:'%I0.0'},{addr:'%I0.1',negated:true},{addr:'%I0.2',negated:true}],coil:{addr:'%Q0.0'}}]}]});
  if(lad?.isError) throw new Error(`tia_build_lad failed: ${JSON.stringify(lad.structuredContent||lad.content||lad)}`);
  const compile=await run('compilation_software',{deviceName});
  return {success:true,project:`${projectDirectory}\\${name}.ap20`,backupPath,deviceName,orderNumber,steps:stepResults,lad,compile};
}
