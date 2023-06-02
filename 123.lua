local player-- 用于存储玩家对象
local doublesw
local playercontroller
local combat 
local playeractionpicker
local attacktimes={}-- 一个空表，用于存储攻击次数
local GUIDS={} -- 一个空表，用于存储GUIDS
local aheadtime=2*GLOBAL.FRAMES-- aheadtime 的值为 2 帧的时间
local ispig=true
local function CheckMod(name)
  for k,v in pairs(GLOBAL.ModManager.mods) do
    if v.modinfo.name == name then
      return true
    end
  end
end
local function IsDefaultScreen()
  local screen = GLOBAL.TheFrontEnd:GetActiveScreen()
  local screenName = screen and screen.name or ""
  --GLOBAL.print(GLOBAL.tostring(screenName))
  return screenName:find("HUD") ~= nil and CheckMod("ReForged") 
end
local function GetTargets()
  local x, y, z = player.Transform:GetWorldPosition()
  local attackRange = combat:GetAttackRangeWithWeapon()
  local entities = GLOBAL.TheSim:FindEntities(x, y, z, 8, {"LA_mob"})
  local targets = {}
  for _, entity in ipairs(entities) do
    if entity:IsValid() and entity.replica.health ~= nil and not entity.replica.health:IsDead() then
      GLOBAL.table.insert(targets, entity)
    end
  end
  return targets
end
local function PlayerHeadMessage(text)
  if not IsDefaultScreen() or GLOBAL.ThePlayer==nil then return end
  GLOBAL.ThePlayer.components.talker:Say(text,nil,nil,nil,nil,{1,1,1,1,})
end
local function CheckDebugString(inst,string)
  if not inst then return end
  local debugstring=inst.entity:GetDebugString()
  if string=="" then GLOBAL.print(debugstring) end
  return debugstring and string.find(debugstring,string)
end
local function GotoPos(tx,tz)
  if playercontroller:CanLocomote() then
    local action = GLOBAL.BufferedAction(playercontroller.inst,nil,GLOBAL.ACTIONS.WALKTO,nil,GLOBAL.Vector3(tx,0,tz))
    playercontroller:DoAction(action)
  else
    GLOBAL.SendRPCToServer(GLOBAL.RPC.LeftClick, GLOBAL.ACTIONS.WALKTO.code, tx, tz, nil, true, nil, nil, nil)
  end
end
local function DoCastAOE(target,px,pz,tx,tz,distance)
  if CheckDebugString(player,"player_parryblock.zip:parry_loop") or CheckDebugString(player,"player_parryblock.zip:parry_pre") then return end
  local rightclick=GLOBAL.ThePlayer.components.playercontroller:GetRightMouseAction() 
  if rightclick and rightclick.action == GLOBAL.ACTIONS.CASTAOE then
    tx=rightclick.pos.local_pt.x
    tz=rightclick.pos.local_pt.z
  end
--GLOBAL.print(tx.."    "..tz)
  if playercontroller:CanLocomote() then
    local weapon = combat:GetWeapon()
    --local act =  GLOBAL.BufferedAction(player, nil, GLOBAL.ACTIONS.CASTAOE, weapon, GLOBAL.Vector3(px-(px-tx)/distance/4,0,pz-(pz-tz)/distance/4), nil, nil, nil, nil)
    local act =  GLOBAL.BufferedAction(player, nil, GLOBAL.ACTIONS.CASTAOE, weapon, GLOBAL.Vector3(tx,0,tz), nil, nil, nil, nil)
    if act == nil then return false end
    act.preview_cb = function()
      --GLOBAL.SendRPCToServer(GLOBAL.RPC.LeftClick, GLOBAL.ACTIONS.CASTAOE.code, px-(px-tx)/distance/4,pz-(pz-tz)/distance/4, nil, true, nil, nil,nil)
      GLOBAL.SendRPCToServer(GLOBAL.RPC.LeftClick, GLOBAL.ACTIONS.CASTAOE.code, tx,tz, nil, true, nil, nil,nil)
    end
    playercontroller:DoAction(act)
  else
    --GLOBAL.SendRPCToServer(GLOBAL.RPC.LeftClick, GLOBAL.ACTIONS.CASTAOE.code, px-(px-tx)/distance/4,pz-(pz-tz)/distance/4, nil, true, nil, nil,nil)
    GLOBAL.SendRPCToServer(GLOBAL.RPC.LeftClick, GLOBAL.ACTIONS.CASTAOE.code, tx,tz, nil, true, nil, nil,nil)
  end
end
--执行施放 AOE 技能的动作，具体取决于玩家控制器是否可以移动。

local function Start()
  if not ispig then PlayerHeadMessage("你不是猪猪别按了") return end
  if not IsDefaultScreen() then return end
  if GLOBAL.ThePlayer == nil then return end
  player = GLOBAL.ThePlayer
  playercontroller = player.components.playercontroller
  combat = player.replica.combat
  playeractionpicker = player.components.playercontroller
  if GLOBAL.ThePlayer.Workthread ~= nil then return end
  GLOBAL.ThePlayer.Workthread = GLOBAL.ThePlayer:StartThread(function()
      while true do
        local weapon = combat:GetWeapon()
        local targets = GetTargets()
        local compensate 
        if playercontroller:CanLocomote() then compensate=1 else compensate=0 end
        --if weapon then CheckDebugString(weapon,"") end
        if weapon and weapon.components.aoetargeting:IsEnabled() then
          if #targets ~= 0 and weapon and GLOBAL.tostring(weapon.prefab)=="blacksmithsedge" then --blacksmithsedge(大剑)--riledlucy(伍迪的老婆)spiralspear-(螺旋矛)
            local rhinocebro=nil
            local rhinocebro2=nil
            local tx0
            local tz0
            local atx0
            local atz0
            for k,target in ipairs(targets) do
              if target.prefab=="rhinocebro2" then rhinocebro2=true end
              if target.prefab=="rhinocebro" then rhinocebro=true end
            end
            if rhinocebro and rhinocebro2 then
              local tx1,ty1,tz1
              local tx2,ty2,tz2
              local px,py,pz = GLOBAL.ThePlayer:GetPosition():Get()
              for k,target in ipairs(targets) do
                if target.prefab=="rhinocebro" then 
                  tx1,ty1,tz1 = target:GetPosition():Get()
                  if tx1==px and tz1==pz then tx1=tx1+0.1 tz1=tz1+0.1 end
                end
                if target.prefab=="rhinocebro2" then 
                  tx2,ty2,tz2 = target:GetPosition():Get()
                  if tx2==px and tz2==pz then tx2=tx2+0.1 tz2=tz2+0.1 end
                end
              end
              tx0=(tx1+tx2)/2
              tz0=(tz1+tz2)/2
              local sint=(tx2-tx1)/GLOBAL.math.sqrt((tz2-tz1)*(tz2-tz1)+(tx2-tx1)*(tx2-tx1))
              local cost=(tz2-tz1)/GLOBAL.math.sqrt((tz2-tz1)*(tz2-tz1)+(tx2-tx1)*(tx2-tx1))
              local atx1=tx0-2*cost
              local atz1=tz0+2*sint
              local atx2=tx0+2*cost
              local atz2=tz0-2*sint
              if GLOBAL.math.sqrt((atx1-px)*(atx1-px)+(atz1-pz)*(atz1-pz)) <= GLOBAL.math.sqrt((atx2-px)*(atx2-px)+(atz2-pz)*(atz2-pz)) then
                atx0=atx1
                atz0=atz1
              else
                atx0=atx2
                atz0=atz2
              end
            end
            for k,target in ipairs(targets) do
              --CheckDebugString(target,"") 
              local tx,ty,tz = target:GetPosition():Get()
              local px,py,pz = GLOBAL.ThePlayer:GetPosition():Get()
              if tx==px and tz==pz then tx=tx+0.1 tz=tz+0.1 end
              local distance = GLOBAL.math.sqrt((px-tx)*(px-tx)+(pz-tz)*(pz-tz))
              local tr = target:GetRotation()
              local pa = GLOBAL.math.atan2(tz - pz, px - tx) / GLOBAL.DEGREES
              --local range = combat:GetAttackRangeWithWeapon()+target:GetPhysicsRadius(0)
              if doublesw and rhinocebro and rhinocebro2 and CheckDebugString(target,"lavaarena_rhinodrill_basic.zip:cheer_pre Frame") then
                GotoPos(atx0,atz0)
              end
              if doublesw and CheckDebugString(target,"lavaarena_rhinodrill_basic.zip:attack Frame: "..GLOBAL.tostring(7+compensate)..".00") 
              and rhinocebro and rhinocebro2 and distance<5 and GLOBAL.math.abs(tr-pa)<15 
              or doublesw and CheckDebugString(target,"lavaarena_rhinodrill_basic.zip:chest_bump Frame: "..GLOBAL.tostring(13+compensate)..".00") 
              and rhinocebro and rhinocebro2 and distance<5 --and GLOBAL.math.abs(tr-pa)<15
              or doublesw and CheckDebugString(target,"lavaarena_rhinodrill_basic.zip:attack2") 
              and distance<4 and GLOBAL.math.abs(tr-pa)<5 and not CheckDebugString(player,"hit") and rhinocebro and rhinocebro2 then
                DoCastAOE(target,px,pz,tx0,tz0,distance) 
              end
              if CheckDebugString(target,"lavaarena_trails_basic.zip:attack1 Frame: "..GLOBAL.tostring(13+compensate)..".00") and distance<5--(猩猩跳)
              or CheckDebugString(target,"lavaarena_trails_basic.zip:attack2 Frame: "..GLOBAL.tostring(3+compensate)..".00") and distance<5 and GLOBAL.math.abs(tr-pa)<45--(猩猩普攻)
              or CheckDebugString(target,"lavaarena_trails_basic.zip:roll_pre Frame: "..GLOBAL.tostring(8+compensate)..".00") and distance<4 and GLOBAL.math.abs(tr-pa)<15--(猩猩滚圈起手)
              or CheckDebugString(target,"lavaarena_trails_basic.zip:roll_loop") and distance<4 and distance>2 and GLOBAL.math.abs(tr-pa)<15--(猩猩滚圈中)
              or CheckDebugString(target,"lavaarena_boarrior_basic.zip:attack1 Frame: "..GLOBAL.tostring(1+compensate)..".00") and distance<5 and GLOBAL.math.abs(tr-pa)<45--(猪魁普攻1段)
              or CheckDebugString(target,"lavaarena_boarrior_basic.zip:attack2 Frame: "..GLOBAL.tostring(1+compensate)..".00") and distance<5 and GLOBAL.math.abs(tr-pa)<45--(猪魁普攻2段)
              or CheckDebugString(target,"lavaarena_boarrior_basic.zip:attack3 Frame: "..GLOBAL.tostring(1+compensate)..".00") and distance<5 and GLOBAL.math.abs(tr-pa)<45--(猪魁普攻3段)
              or CheckDebugString(target,"lavaarena_boarrior_basic.zip:attack4 Frame: "..GLOBAL.tostring(2+compensate)..".00") and distance<5--lavaarena_boarrior_basic.zip:attack4(猪魁转圈)
              or CheckDebugString(target,"lavaarena_boarrior_basic.zip:attack5 Frame: "..GLOBAL.tostring(6+compensate)..".00") and distance<8 and GLOBAL.math.abs(tr-pa)<10--(猪魁抓地1段)
              or CheckDebugString(target,"lavaarena_boarrior_basic.zip:attack5 Frame: "..GLOBAL.tostring(30+compensate)..".00") and distance<8 and GLOBAL.math.abs(tr-pa)<10--(猪魁抓地2段)
              or CheckDebugString(target,"lavaarena_rhinodrill_basic.zip:attack Frame: "..GLOBAL.tostring(6+compensate)..".00") 
              and distance<5 and GLOBAL.math.abs(tr-pa)<30 and not (doublesw and rhinocebro and rhinocebro2 )--(犀牛普攻)
              or CheckDebugString(target,"lavaarena_rhinodrill_basic.zip:attack2") and not CheckDebugString(player,"hit")
              and distance<4 and GLOBAL.math.abs(tr-pa)<5 and not (doublesw and rhinocebro and rhinocebro2 )--(犀牛冲撞)
              or CheckDebugString(target,"lavaarena_rhinodrill_basic.zip:chest_bump Frame: "..GLOBAL.tostring(13+compensate)..".00") 
              and distance<4 and not (doublesw and rhinocebro and rhinocebro2 )--(犀牛冲撞)
              or CheckDebugString(target,"lavaarena_beetletaur_actions.zip:attack1 Frame: "..GLOBAL.tostring(0+compensate)..".00") and distance<5 and GLOBAL.math.abs(tr-pa)<45--(绿猪普攻1段)
              or CheckDebugString(target,"lavaarena_beetletaur_actions.zip:attack2 Frame: "..GLOBAL.tostring(0+compensate)..".00") and distance<5 and GLOBAL.math.abs(tr-pa)<45--(绿猪普攻2段)
              or CheckDebugString(target,"lavaarena_beetletaur_actions.zip:attack1b Frame: "..GLOBAL.tostring(0+compensate)..".00") and distance<5 and GLOBAL.math.abs(tr-pa)<45--(绿猪连拳b段)
              or CheckDebugString(target,"lavaarena_beetletaur_basic.zip:taunt2 Frame: "..GLOBAL.tostring(0+compensate)..".00") and distance<5--(绿猪捶地)
              or CheckDebugString(target,"lavaarena_beetletaur_actions.zip:bellyflop Frame: "..GLOBAL.tostring(12+compensate)..".00") and (GLOBAL.math.abs(tr-pa)<30 or distance<5)--(绿猪跳)
              or CheckDebugString(target,"lavaarena_beetletaur_block.zip:block_counter Frame: "..GLOBAL.tostring(0+compensate)..".00") and distance<5 and GLOBAL.math.abs(tr-pa)<45--(绿猪点攻)
              then 
                --GLOBAL.print("DoCastAOE")
                DoCastAOE(target,px,pz,tx,tz,distance)            
              end
            end
          elseif #targets ~= 0 and weapon and (GLOBAL.tostring(weapon.prefab)=="riledlucy" or GLOBAL.tostring(weapon.prefab)=="spiralspear" or GLOBAL.tostring(weapon.prefab)=="forginghammer") then --blacksmithsedge(大剑)--riledlucy(伍迪的老婆)--forginghammer(锤子)
            for k,target in ipairs(targets) do
              --CheckDebugString(target,"") 
              local tx,ty,tz = target:GetPosition():Get()
              local px,py,pz = GLOBAL.ThePlayer:GetPosition():Get()
              if tx==px and tz==pz then tx=tx+0.1 tz=tz+0.1 end
              local distance = GLOBAL.math.sqrt((px-tx)*(px-tx)+(pz-tz)*(pz-tz))
              local tr = target:GetRotation()
              local pa = GLOBAL.math.atan2(tz - pz, px - tx) / GLOBAL.DEGREES
              --local range = combat:GetAttackRangeWithWeapon()+target:GetPhysicsRadius(0)
              for k,v in ipairs(GUIDS) do
                if v==target.GUID then
                  --GLOBAL.print(attacktimes[2*k])
                  --GLOBAL.print(attacktimes[2*k+1])
                  --GLOBAL.print(distance)
                  --GLOBAL.print(GLOBAL.math.abs(tr-pa))
                  if not (CheckDebugString(target,"zip:fossilized") --石化的
                    or CheckDebugString(target,"zip:sleep") --睡着的
                    or CheckDebugString(target,"zip:stun") --被电的
                    or CheckDebugString(target,"zip:banner") --插旗子的
                    or CheckDebugString(target,"zip:taunt")) then --战吼的
                    if CheckDebugString(target,"pitpig") and distance<4 and GLOBAL.math.abs(tr-pa)<30 --小猪在攻击范围内
                    and (attacktimes[2*k]==nil or GLOBAL.GetTime() - attacktimes[2*k]>=54*GLOBAL.FRAMES-aheadtime) --小猪攻击冷却
                    --and not (CheckDebugString(target,"hit") and not CheckDebugString(target,"hit Frame: "..GLOBAL.tostring(11+compensate)..".00"))--小猪挨打
                    or CheckDebugString(target,"crocommander") and distance<4 and GLOBAL.math.abs(tr-pa)<10--鳄鱼在攻击范围内
                    and (attacktimes[2*k]==nil or GLOBAL.GetTime() - attacktimes[2*k]>=30*GLOBAL.FRAMES-aheadtime) --鳄鱼攻击冷却
                    and not(CheckDebugString(target,"hit") and not CheckDebugString(target,"hit Frame: "..GLOBAL.tostring(11+compensate)..".00"))--鳄鱼挨打
                    or CheckDebugString(target,"snortoise") and distance<3.5 and GLOBAL.math.abs(tr-pa)<30--乌龟在范围内
                    and (attacktimes[2*k]==nil or GLOBAL.GetTime() - attacktimes[2*k]>=88*GLOBAL.FRAMES-aheadtime) --乌龟攻击冷却
                    and not (CheckDebugString(target,"hit") and not CheckDebugString(target,"hit Frame: "..GLOBAL.tostring(7+compensate)..".00"))--乌龟挨打
                    and not (CheckDebugString(target,"hide") and not CheckDebugString(target,"hide_pst Frame: "..GLOBAL.tostring(15+compensate)..".00"))--乌龟防御
                    or CheckDebugString(target,"attack2") and (GLOBAL.math.abs(tr-pa)<15 and distance>4  and distance<12  or GLOBAL.math.abs(tr-pa-180)<15 and distance<12 )--乌龟转圈
                    or CheckDebugString(target,"scorpeon") and distance<4 and GLOBAL.math.abs(tr-pa)<30--蝎子在范围内
                    and (attacktimes[2*k]==nil  
                      or (attacktimes[2*k+1]==nil and GLOBAL.GetTime() - attacktimes[2*k]>=86*GLOBAL.FRAMES-aheadtime) --蝎子攻击冷却
                      or (attacktimes[2*k+1]~=nil and GLOBAL.GetTime() - attacktimes[2*k]>=42*GLOBAL.FRAMES-aheadtime))--蝎子两个阶段攻击间隔不同
                    and not (CheckDebugString(target,"hit") and not CheckDebugString(target,"hit Frame: "..GLOBAL.tostring(9+compensate)..".00"))--蝎子挨打
                    or CheckDebugString(target,"boarilla") and distance<4 and GLOBAL.math.abs(tr-pa)<30--猩猩在攻击范围内
                    and (attacktimes[2*k]==nil or GLOBAL.GetTime() - attacktimes[2*k]>=100*GLOBAL.FRAMES-aheadtime)--猩猩攻击冷却
                    and not (CheckDebugString(target,"hit") and not CheckDebugString(target,"hit Frame: "..GLOBAL.tostring(13+compensate)..".00"))--猩猩挨打
                    and not (CheckDebugString(target,"hide") and not CheckDebugString(target,"hide_pst Frame: "..GLOBAL.tostring(9+compensate)..".00"))--猩猩防御
                    or CheckDebugString(target,"boarrior") and distance<4 and GLOBAL.math.abs(tr-pa)<30--猪魁在范围内
                    and (attacktimes[2*k]==nil or GLOBAL.GetTime() - attacktimes[2*k]>=100*GLOBAL.FRAMES-aheadtime)--猪魁攻击冷却
                    and not (CheckDebugString(target,"hit") and not CheckDebugString(target,"hit Frame: "..GLOBAL.tostring(12+compensate)..".00"))--猪魁挨打
                    or CheckDebugString(target,"rhinocebro") and distance<4 and GLOBAL.math.abs(tr-pa)<30--犀牛在范围内
                    and (attacktimes[2*k]==nil or GLOBAL.GetTime() - attacktimes[2*k]>=90*GLOBAL.FRAMES-aheadtime)--犀牛攻击冷却
                    --and not (CheckDebugString(target,"hit") and not CheckDebugString(target,"lavaarena_rhinodrill_basic.zip:hit Frame: "..GLOBAL.tostring(0+compensate)..".00"))--犀牛挨打
                    or CheckDebugString(target,"cheer")--犀牛加buff
                    or CheckDebugString(target,"swineclops") and distance<5 and GLOBAL.math.abs(tr-pa)<30--绿猪在范围内
                    and ((CheckDebugString(target,"block") and (attacktimes[2*k]==nil or GLOBAL.GetTime() - attacktimes[2*k]>=32*GLOBAL.FRAMES-aheadtime))--防御状态绿猪攻击冷却
                      or ((attacktimes[2*k]==nil or GLOBAL.GetTime() - attacktimes[2*k]>=115*GLOBAL.FRAMES-aheadtime))--绿猪攻击冷却
                      and not CheckDebugString(target,"lavaarena_beetletaur_actions.zip:bellyflop")--绿猪跳砸 
                      and not (CheckDebugString(target,"hit") and not CheckDebugString(target,"hit Frame: "..GLOBAL.tostring(7+compensate)..".00")))--绿猪挨打
                    or CheckDebugString(target,"lavaarena_swineclops_basic.zip:taunt2")--绿猪锤地板
                    or CheckDebugString(target,"lavaarena_beetletaur_actions.zip:attack")--绿猪普通攻击已经出手
                    then 
                      --GLOBAL.print("DoCastAOE")
                      DoCastAOE(target,px,pz,tx,tz,distance)
                    end
                  end
                end
              end
            end
          end
        end
        GLOBAL.Sleep(0*GLOBAL.FRAMES)
      end
    end)
  if GLOBAL.ThePlayer.Scanthread ~= nil then return end
  GLOBAL.ThePlayer.Scanthread = GLOBAL.ThePlayer:StartThread(function()
      while true do  
        local compensate 
        if playercontroller:CanLocomote() then compensate=1 else compensate=0 end
        local x, y, z = player.Transform:GetWorldPosition()
        local entities = GLOBAL.TheSim:FindEntities(x, y, z, 8, {"LA_mob"})
        for _, entity in ipairs(entities) do
          local inguids = false
          for k,v in ipairs(GUIDS) do 
            if entity.GUID== GUIDS[k] then inguids=true break end
          end
          if not inguids then 
            GUIDS[#GUIDS+1]=entity.GUID 
          end
          for k,v in ipairs(GUIDS) do 
            if v ==entity.GUID then 
              --CheckDebugString(entity,"")
              if CheckDebugString(entity,"lavaarena_boaron_basic.zip:attack1 Frame: "..GLOBAL.tostring(0+compensate)..".00")--小猪攻击
              or CheckDebugString(entity,"lavaarena_boaron_basic.zip:attack2 Frame: "..GLOBAL.tostring(0+compensate)..".00")--小猪冲撞
              or CheckDebugString(entity,"lavaarena_snapper_rapidfire.zip:attack Frame: ")and (attacktimes[2*k]==nil or GLOBAL.GetTime()-attacktimes[2*k]>=25*GLOBAL.FRAMES)--加强鳄鱼咬
              or CheckDebugString(entity,"lavaarena_snapper_rapidfire.zip:spit Frame: "..GLOBAL.tostring(0+compensate)..".00")--加强鳄鱼吐口水
              or CheckDebugString(entity,"lavaarena_snapper_basic.zip:attack Frame: ")and (attacktimes[2*k]==nil or GLOBAL.GetTime()-attacktimes[2*k]>=25*GLOBAL.FRAMES)--鳄鱼咬
              or CheckDebugString(entity,"lavaarena_snapper_basic.zip:spit Frame: "..GLOBAL.tostring(0+compensate)..".00")--鳄鱼吐口水
              or CheckDebugString(entity,"lavaarena_turtillus_basic.zip:attack1 Frame: "..GLOBAL.tostring(0+compensate)..".00")--乌龟攻击
              or CheckDebugString(entity,"lavaarena_turtillus_basic.zip:attack2 Frame: "..GLOBAL.tostring(0+compensate)..".00")--乌龟转圈
              or CheckDebugString(entity,"lavaarena_peghook_basic.zip:attack_pre Frame: "..GLOBAL.tostring(0+compensate)..".00")--蝎子攻击
              or CheckDebugString(entity,"lavaarena_peghook_basic.zip:spit Frame: "..GLOBAL.tostring(0+compensate)..".00")--蝎子喷毒
              or CheckDebugString(entity,"lavaarena_trails_basic.zip:attack1 Frame: "..GLOBAL.tostring(0+compensate)..".00")--猩猩跳
              or CheckDebugString(entity,"lavaarena_trails_basic.zip:attack2 Frame: "..GLOBAL.tostring(0+compensate)..".00")--猩猩普通攻击
              or CheckDebugString(entity,"lavaarena_trails_basic.zip:roll_pre Frame: "..GLOBAL.tostring(0+compensate)..".00")--猩猩打滚
              or CheckDebugString(entity,"lavaarena_boarrior_basic.zip:attack1 Frame: "..GLOBAL.tostring(0+compensate)..".00")--朱奎普通攻击
              or CheckDebugString(entity,"lavaarena_boarrior_basic.zip:attack4 Frame: "..GLOBAL.tostring(0+compensate)..".00")--朱奎抓地
              or CheckDebugString(entity,"lavaarena_boarrior_basic.zip:attack5 Frame: "..GLOBAL.tostring(0+compensate)..".00")--朱奎转圈
              or CheckDebugString(entity,"lavaarena_rhinodrill_basic.zip:attack Frame: "..GLOBAL.tostring(0+compensate)..".00")--犀牛普通攻击
              or CheckDebugString(entity,"lavaarena_rhinodrill_basic.zip:attack2_pre Frame: "..GLOBAL.tostring(0+compensate)..".00")--犀牛冲撞
              or CheckDebugString(entity,"lavaarena_beetletaur_actions.zip:attack1 Frame: "..GLOBAL.tostring(0+compensate)..".00")--绿猪普通攻击1
              or CheckDebugString(entity,"lavaarena_beetletaur_actions.zip:attack2 Frame: "..GLOBAL.tostring(0+compensate)..".00")--绿猪普通攻击2
              or CheckDebugString(entity,"lavaarena_beetletaur_actions.zip:attack3 Frame: "..GLOBAL.tostring(0+compensate)..".00")--绿猪普通攻击3
              or CheckDebugString(entity,"lavaarena_beetletaur_actions.zip:attack1b Frame: "..GLOBAL.tostring(0+compensate)..".00")--绿猪普通攻击1b
              --or CheckDebugString(entity,"lavaarena_beetletaur_basic.zip:taunt2 Frame: "..GLOBAL.tostring(0+compensate)..".00")--绿猪锤地
              --or CheckDebugString(entity,"lavaarena_beetletaur_actions.zip:bellyflop Frame: "..GLOBAL.tostring(0+compensate)..".00")--绿猪跳砸
              or CheckDebugString(entity,"lavaarena_beetletaur_block.zip:block_counter Frame: "..GLOBAL.tostring(0+compensate)..".00") then--绿猪防御反击
                attacktimes[2*k]=GLOBAL.GetTime()
                --GLOBAL.print(attacktimes[2*k])
              end
              if CheckDebugString(entity,"lavaarena_peghook_basic.zip:spit Frame: "..GLOBAL.tostring(0+compensate)..".00") then--蝎子喷毒
                attacktimes[2*k+1]=GLOBAL.GetTime()
              end
            end
          end
        end
        GLOBAL.Sleep(0*GLOBAL.FRAMES)
      end
    end)
end
local function Stop()
  if IsDefaultScreen() and GLOBAL.ThePlayer ~= nil and GLOBAL.ThePlayer.Workthread ~= nil then
    GLOBAL.ThePlayer.Workthread:SetList(nil)
    GLOBAL.ThePlayer.Workthread = nil
  end
end
local function GetKeyFromConfig(config)
  local key = GetModConfigData(config, true)
  if type(key) == "string" and GLOBAL:rawget(key) then
    key = GLOBAL[key]
  end
  return type(key) == "number" and key or -1
end
if GetKeyFromConfig("Attack_key") then
  GLOBAL.TheInput:AddKeyUpHandler(GetKeyFromConfig("Attack_key"),Stop)
  GLOBAL.TheInput:AddKeyDownHandler(GetKeyFromConfig("Attack_key"),Start)
end
GLOBAL.TheInput:AddKeyUpHandler(GLOBAL.KEY_UP,function()
    if not IsDefaultScreen() then return end
    aheadtime=aheadtime+GLOBAL.FRAMES
    if aheadtime>100*GLOBAL.FRAMES then aheadtime=100*GLOBAL.FRAMES end
    GLOBAL.print("aheadtime="..GLOBAL.tostring(GLOBAL.math.floor(aheadtime/GLOBAL.FRAMES+0.1)))
  end)
GLOBAL.TheInput:AddKeyUpHandler(GLOBAL.KEY_DOWN,function()
    if not IsDefaultScreen() then return end
    aheadtime=aheadtime-GLOBAL.FRAMES
    if aheadtime<0*GLOBAL.FRAMES then aheadtime=0*GLOBAL.FRAMES end
    GLOBAL.print("aheadtime="..GLOBAL.tostring(GLOBAL.math.floor(aheadtime/GLOBAL.FRAMES+0.1)))
  end)
if GetKeyFromConfig("Auto_Attack_key") then
  GLOBAL.TheInput:AddKeyUpHandler(GetKeyFromConfig("Auto_Attack_key"),function()
      if not IsDefaultScreen() or GLOBAL.ThePlayer == nil then return end
      if GLOBAL.ThePlayer.Workthread ~= nil then
        Stop()
      else
        Start()
      end
    end)
end
if GetKeyFromConfig("doublesw_key") then
  GLOBAL.TheInput:AddKeyUpHandler(GetKeyFromConfig("doublesw_key"),function()
      if not IsDefaultScreen() or GLOBAL.ThePlayer == nil then return end
      if doublesw then doublesw=false else doublesw = true end
      GLOBAL.print("双扛犀牛：".."  "..GLOBAL.tostring(doublesw))
    end)
end
local function areyoupig(text,value) 
  ispig=true 
  PlayerHeadMessage("猪人就要大开杀戒啦！")
end
local command_data = 
{
  name = "我是猪猪",
  prettyname = nil,
  desc = nil,
  permission = GLOBAL.COMMAND_PERMISSION.USER,
  slash = true,	
  usermenu = false,
  servermenu = false,
  params = {} ,
  localfn = areyoupig
}
AddUserCommand(command_data.name , command_data)
