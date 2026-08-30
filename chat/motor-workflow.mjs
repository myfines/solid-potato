const defaultOrderNumber='6ES7 214-1BG40-0XB0';
function findProjectPath(result){
  const seen=new Set();
  const visit=value=>{
    if(value==null||seen.has(value))return null;
    if(typeof value==='string'){if(/\.(ap20|ap19|ap18)$/i.test(value))return value;try{return visit(JSON.parse(value))}catch{return null}}
    if(typeof value!=='object')return null; seen.add(value);
    for(const key of ['path','projectPath','filePath']){if(value[key]){const found=visit(value[key]);if(found)return found}}
    for(const value2 of Object.values(value)){const found=visit(value2);if(found)return found}
    return null;
  };
  return visit(result);
}
function findTagTableName(result){
  const seen=new Set();
  const visit=value=>{
    if(value==null||seen.has(value))return null;
    if(typeof value==='string'){try{return visit(JSON.parse(value))}catch{return null}}
    if(typeof value!=='object')return null; seen.add(value);
    for(const key of ['name','tableName','tagTableName']) if(typeof value[key]==='string'&&value[key]) return value[key];
    for(const value2 of Object.values(value)){const found=visit(value2);if(found)return found}
    return null;
  };
  return visit(result);
}

export async function buildMotorProject({client, name, projectDirectory, backupPath, deviceName='PLC_1', orderNumber=defaultOrderNumber, call}) {
  const stepResults=[];
  const run=async(tool, args)=>{
    const result=await call(tool,args);
    if(result?.isError) throw new Error(`${tool} failed: ${JSON.stringify(result.structuredContent||result.content||result)}`);
    stepResults.push({tool,success:true});
    return result;
  };
  const session=await run('projects_get_session_info',{});
  let activeProjectPath=findProjectPath(session)||'';
  const sessionText=JSON.stringify(session);
  if(!/hasOpenProject[^a-zA-Z]+true/.test(sessionText)) {
    let created;
    try { created=await run('projects_create',{name,path:projectDirectory}); }
    catch (createError) {
      const message=String(createError?.message||createError);
      if(!/already open|project.*open|已有.*工程/i.test(message)) throw createError;
      stepResults.push({tool:'session_cleanup_warning',success:false,message:'检测到已有工程；即将关闭当前工程后继续隔离测试'});
      const current=await call('projects_get_session_info',{});
      const currentPath=findProjectPath(current);
      if(currentPath&&backupPath) await call('tia_backup_project',{project:currentPath,backupPath:`${backupPath}\\ExistingProject_Before_AutoClose`});
      try { await run('projects_close',{}); } catch (closeError) {
        if(!/no project|没有工程/i.test(String(closeError?.message||closeError))) throw closeError;
      }
      await new Promise(resolve=>setTimeout(resolve,1000));
      created=await run('projects_create',{name,path:projectDirectory});
    }
    const createdPath=findProjectPath(created)||`${projectDirectory}\\${name}.ap20`;
    let opened=false; let lastOpenError;
    const openPaths=[createdPath,projectDirectory];
    for(const delay of [1500,4000,8000]) {
      await new Promise(resolve=>setTimeout(resolve,delay));
      for(const openPath of openPaths) { try { await run('projects_open',{projectPath:openPath}); opened=true; break; } catch (error) { lastOpenError=error; } }
      if(opened) break;
    }
    if(!opened) throw lastOpenError||new Error(`Unable to open created project: ${createdPath}`);
    activeProjectPath=createdPath;
  } else if(!sessionText.includes(name)) {
    throw new Error('TIA 当前已有其他工程打开；为保护用户工程，已停止。请关闭当前工程后再创建隔离项目，或明确指定复用当前工程。');
  }
  await run('devices_create',{deviceName,orderNumber,dryRun:false});
  const tagTables=await run('tags_tagtable_list',{deviceName,includeCounts:false});
  const tagTableName=findTagTableName(tagTables)||'System';
  const tags=[
    ['Start_Button','%I0.0'],['Stop_Button','%I0.1'],['Emergency_Stop','%I0.2'],['Reset_Button','%I0.3'],
    ['Motor_Run','%Q0.0'],['Run_Lamp','%Q0.1'],['Fault_Lamp','%Q0.2']
  ];
  for(const [tagName,logicalAddress] of tags) await run('tags_create',{deviceName,tagTableName,tagName,dataType:'Bool',logicalAddress});
  await run('projects_save',{});
  if(backupPath) await call('tia_backup_project',{project:activeProjectPath||`${projectDirectory}\\${name}.ap20`,backupPath});
  const lad=await call('tia_build_lad',{projectMatch:name,deviceName,name:'Main',blockType:'OB',blockNumber:1,networks:[{title:'Motor starter',rungs:[{contacts:[{addr:'%I0.0'},{addr:'%I0.1',negated:true},{addr:'%I0.2',negated:true}],coil:{addr:'%Q0.0'}}]}]});
  if(lad?.isError) throw new Error(`tia_build_lad failed: ${JSON.stringify(lad.structuredContent||lad.content||lad)}`);
  const compile=await run('compilation_software',{deviceName});
  return {success:true,project:`${projectDirectory}\\${name}.ap20`,backupPath,deviceName,orderNumber,steps:stepResults,lad,compile};
}
