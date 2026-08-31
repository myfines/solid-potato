import { mkdir, readdir, access } from 'node:fs/promises';
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
async function hasEntries(path){try{return (await readdir(path)).length>0}catch{return false}}
async function resolveProjectFile(candidates){for(const candidate of candidates){try{await access(candidate);return candidate}catch{}}return candidates[0]}
function validSimpleLad(networks){return Array.isArray(networks)&&networks.length>0&&networks.every(n=>Array.isArray(n?.rungs)&&n.rungs.length>0&&n.rungs.every(r=>Array.isArray(r.contacts)&&r.contacts.length>0&&r.contacts.every(c=>typeof c?.addr==='string')&&r.coil&&typeof r.coil.addr==='string'))}

export async function buildMotorProject({client, name, projectDirectory, backupPath, deviceName='PLC_1', orderNumber=defaultOrderNumber, call, report=()=>{}, fbName='Motor_Starter', instanceDb='Motor_Starter_DB', tags:customTags, sclContent, ladNetworks}) {
  if(!String(name||'').trim()) throw new Error('项目名称不能为空');
  if(!String(projectDirectory||'').match(/^[A-Za-z]:[\\/]/)) throw new Error('项目目录必须是绝对路径');
  if(!String(backupPath||'').match(/^[A-Za-z]:[\\/]/)) throw new Error('备份目录必须是绝对路径');
  if(String(orderNumber||'').trim()!==defaultOrderNumber){report('warning',`CPU 料号 ${orderNumber} 不适用于当前 V20 流程，已自动修正为 ${defaultOrderNumber}`);orderNumber=defaultOrderNumber;}
  // TIA device names are identifiers, not display titles. Models sometimes
  // copy the project title (including spaces) into this field. Normalize it
  // before the irreversible device-create call and make the correction visible.
  if(!/^[A-Za-z_][A-Za-z0-9_]*$/.test(String(deviceName||''))){
    const original=String(deviceName||'');
    deviceName='PLC_1';
    report('warning',`设备名称“${original}”不是 TIA 合法标识符，已自动修正为 ${deviceName}`);
  }
  if(ladNetworks!==undefined&&!validSimpleLad(ladNetworks)) throw new Error('LAD 网络格式无效：必须提供至少一个包含 contacts 和 coil.addr 的 rung；任务已停止，未使用静默回退网络');
  const stepResults=[];
  let effectiveProjectDirectory=projectDirectory;
  await mkdir(projectDirectory,{recursive:true});
  const controlFbName=fbName||'Motor_Starter';
  const controlDbName=instanceDb||`${controlFbName}_DB`;
  const run=async(tool, args)=>{
    report('running',`工作流步骤：${tool}`); const stepStarted=Date.now(); const result=await call(tool,args);
    if(result?.isError) throw new Error(`${tool} failed: ${JSON.stringify(result.structuredContent||result.content||result)}`);
    report('success',`工作流步骤：${tool} 完成（${Date.now()-stepStarted}ms）`);
    stepResults.push({tool,success:true});
    return result;
  };
  const session=await run('projects_get_session_info',{});
  let activeProjectPath=findProjectPath(session)||'';
  const sessionText=JSON.stringify(session);
  if(!/hasOpenProject[^a-zA-Z]+true/.test(sessionText)) {
    let created;
    if(await hasEntries(`${projectDirectory}\\${name}`)) {
      effectiveProjectDirectory=`${projectDirectory}\\${name}_Run_${Date.now()}`;
      await mkdir(effectiveProjectDirectory,{recursive:true});
      report('warning',`目标目录已有工程，直接使用隔离目录：${effectiveProjectDirectory}`);
    }
    try { created=await run('projects_create',{name,path:effectiveProjectDirectory}); }
    catch (createError) {
      const message=String(createError?.message||createError);
      if(/非空|not empty|cannot be created under/i.test(message)) {
        effectiveProjectDirectory=`${projectDirectory}\\${name}_Run_${Date.now()}`;
        await mkdir(effectiveProjectDirectory,{recursive:true});
        report('warning',`目标目录已有工程，保留旧工程并改用隔离目录：${effectiveProjectDirectory}`);
        created=await run('projects_create',{name,path:effectiveProjectDirectory,retry:true});
      } else {
      if(!/already open|project.*open|已有.*工程/i.test(message)) throw createError;
      stepResults.push({tool:'session_cleanup_warning',success:false,message:'检测到已有工程；即将关闭当前工程后继续隔离测试'});
      const current=await call('projects_get_session_info',{});
      const currentPath=findProjectPath(current);
      if(currentPath&&backupPath) await call('tia_backup_project',{project:currentPath,backupPath:`${backupPath}\\ExistingProject_Before_AutoClose`});
      try { await run('projects_close',{}); } catch (closeError) {
        if(!/no project|没有工程/i.test(String(closeError?.message||closeError))) throw closeError;
      }
      await new Promise(resolve=>setTimeout(resolve,1000));
      created=await run('projects_create',{name,path:effectiveProjectDirectory});
      }
    }
    const createdHint=findProjectPath(created)||`${effectiveProjectDirectory}\\${name}.ap20`;
    const createdPath=await resolveProjectFile([createdHint,`${effectiveProjectDirectory}\\${name}.ap20`,`${effectiveProjectDirectory}\\${name}\\${name}.ap20`,`${projectDirectory}\\${name}\\${name}.ap20`]);
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
  const createdDevice=await run('devices_create',{deviceName,orderNumber,dryRun:false});
  const returnedDeviceName=createdDevice?.structuredContent?.data?.deviceName||createdDevice?.structuredContent?.deviceName;
  if(typeof returnedDeviceName==='string'&&returnedDeviceName.trim()&&returnedDeviceName!==deviceName){
    report('warning',`TIA 实际返回设备名称“${returnedDeviceName}”，后续步骤改用该名称`);
    deviceName=returnedDeviceName;
  }
  const tagTables=await run('tags_tagtable_list',{deviceName,includeCounts:false});
  const tagTableName=findTagTableName(tagTables)||'System';
  const tags=customTags?.length?customTags.map(tag=>Array.isArray(tag)?tag:[tag.tagName||tag.name,tag.logicalAddress||tag.address||tag.addr]):[
    ['Start_Button','%I0.0'],['Stop_Button','%I0.1'],['Emergency_Stop','%I0.2'],['Reset_Button','%I0.3'],
    ['Motor_Run','%Q0.0'],['Run_Lamp','%Q0.1'],['Fault_Lamp','%Q0.2']
  ];
  const tagAddress=tagName=>tags.find(([n])=>n===tagName)?.[1];
  const fallbackLadNetworks=customTags?.length?[{title:'Conveyor run',rungs:[{contacts:[{addr:tagAddress('Start_Button')||'%I0.0'},{addr:tagAddress('Stop_Button')||'%I0.1',negated:true},{addr:tagAddress('Emergency_Stop')||'%I0.2',negated:true}],coil:{addr:tagAddress('Conveyor_Motor')||'%Q0.0'}}]},{title:'Full condition',rungs:[{contacts:[{addr:tagAddress('Sensor_Entry')||'%I0.4'},{addr:tagAddress('Sensor_Exit')||'%I0.5'}],coil:{addr:tagAddress('Full_Lamp')||'%Q0.3'}}]}]:null;
  for(const [tagName,logicalAddress] of tags) await run('tags_create',{deviceName,tagTableName,tagName,dataType:'Bool',logicalAddress});
  await run('projects_save',{});
  if(backupPath) await call('tia_backup_project',{project:activeProjectPath||`${effectiveProjectDirectory}\\${name}.ap20`,backupPath});
  const fbSource=sclContent||`FUNCTION_BLOCK "${controlFbName}"\nVERSION : 0.1\nVAR_INPUT\n Start_Button : Bool;\n Stop_Button : Bool;\n Emergency_Stop : Bool;\n Reset_Button : Bool;\nEND_VAR\nVAR_OUTPUT\n Motor_Run : Bool;\n Run_Lamp : Bool;\n Fault_Lamp : Bool;\nEND_VAR\nVAR\n Fault_Active : Bool;\nEND_VAR\nBEGIN\n IF #Emergency_Stop THEN\n  #Fault_Active := TRUE;\n END_IF;\n IF #Reset_Button AND NOT #Emergency_Stop THEN\n  #Fault_Active := FALSE;\n END_IF;\n IF #Stop_Button OR #Emergency_Stop OR #Fault_Active THEN\n  #Motor_Run := FALSE;\n ELSIF #Start_Button THEN\n  #Motor_Run := TRUE;\n END_IF;\n #Run_Lamp := #Motor_Run;\n #Fault_Lamp := #Fault_Active;\nEND_FUNCTION_BLOCK\n\nDATA_BLOCK "${controlDbName}" "${controlFbName}"\nBEGIN\nEND_DATA_BLOCK`;
  report('running',`工作流步骤：生成并编译 ${controlFbName} SCL`); const sclStarted=Date.now(); await call('tia_apply_scl',{project:activeProjectPath||`${effectiveProjectDirectory}\\${name}.ap20`,deviceName,sourceName:`${controlFbName}_FB_DB_Source`,filePath:`${effectiveProjectDirectory}\\${name}_${controlFbName}_FB_DB.scl`,content:fbSource,overwrite:true}); report('success',`工作流步骤：${controlFbName} SCL 完成（${Date.now()-sclStarted}ms）`);
  report('running','工作流步骤：生成 Main/OB1 LAD'); const ladStarted=Date.now();
  const selectedLadNetworks=validSimpleLad(ladNetworks)?ladNetworks:(fallbackLadNetworks||[{title:'Motor starter',rungs:[{contacts:[{addr:'%I0.0'},{addr:'%I0.1',negated:true},{addr:'%I0.2',negated:true}],coil:{addr:'%Q0.0'}}]}]);
  const lad=await call('tia_build_lad',{projectMatch:name,deviceName,name:'Main',blockType:'OB',blockNumber:1,networks:selectedLadNetworks});
  if(lad?.isError) throw new Error(`tia_build_lad failed: ${JSON.stringify(lad.structuredContent||lad.content||lad)}`);
  report('success',`工作流步骤：Main/OB1 LAD 完成（${Date.now()-ladStarted}ms）`);
  const compile=await run('compilation_software',{deviceName});
  // Never report a successful workflow with a guessed path. Re-resolve and
  // verify the actual .ap20 artifact created by TIA before returning.
  const verifiedProjectPath=await resolveProjectFile([
    activeProjectPath,
    `${effectiveProjectDirectory}\\${name}.ap20`,
    `${effectiveProjectDirectory}\\${name}\\${name}.ap20`,
    `${projectDirectory}\\${name}\\${name}.ap20`
  ]);
  try { await access(verifiedProjectPath); } catch { throw new Error(`工程创建步骤已返回成功，但磁盘上找不到真实 .ap20 文件：${verifiedProjectPath}`); }
  activeProjectPath=verifiedProjectPath;
  return {success:true,project:activeProjectPath,backupPath,deviceName,orderNumber,steps:stepResults,lad,compile};
}
