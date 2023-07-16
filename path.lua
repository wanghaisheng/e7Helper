path = {}

path.游戏开始 = function ()
  path.游戏首页()
  path.任务队列()
end

-- isBack: 通过按back来回退
path.游戏首页 = function ()
  current_server = getUIRealValue('服务器', '服务器')
  isBack = true
  if not sAppIsRunning(current_server) or not sAppIsFront(current_server) then 
    isBack = false
    open(server_pkg_name[current_server]) 
  end
  setControlBarPosNew(0, 1)
  local clickTarget = {'cmp_国服签到右下蓝底', 'cmp_国服签到右下蓝底2', 
                       'cmp_国服公告X', 'cmp_国服登录第七史诗', 'cmp_国服放弃战斗', 'cmp_国服结束啊'}
  if wait(function ()
    -- 服务器维护中
    if findOne('cmp_国服服务器维护中') then return 'exit' end
    if not longAppearMomentDisAppear('cmp_国服主页Rank', nil, nil, 1) then return 1 end
    if not findTap(clickTarget) then
      if not isBack then 
        stap(point.回退) 
      else
        back()
      end
    end
  end, 1, 7 * 60) == 'exit' then
    slog('服务器维护中...')
    exit()  
  end
end

path.任务队列 = function ()
  local allTask = table.filter(ui_option.任务, function (v)
    return not v:includes({'社团签到', 
                           '社团奖励', 
                           '社团捐赠'})
  end)
  local curTaskIndex = sgetNumberConfig("current_task_index", 0)
  for i,v in pairs(allTask) do
    if i > curTaskIndex and current_task[v] then
      -- 0 表示异常
      -- 1 或者 nil 表示 ok 
      -- 2 表示重做
      if path[v]() == 2 then path.回到主页() path[v]() end
      slog(v..'完成')
      setNumberConfig("exception_count", 1)
      path.回到主页()
    end
    setNumberConfig('current_task_index', i)
  end
end

-- finish
path.社团开启 = function ()
  -- if not findOne('cmp_国服骑士团红点') then log('骑士团签到无需处理') return 1 end
  wait(function ()
    stap(point.社团)
    ssleep(1)
    if not findOne('cmp_国服主页Rank') then return 1 end
  end)
  wait(function ()
    stap({447,47})
    if findOne('cmp_国服左上骑士团') then return 1 end
  end)

  if current_task.社团签到 then path.社团签到() end
  if current_task.社团捐赠 then path.社团捐赠() end
  if current_task.社团奖励 then path.社团奖励() end

end

path.社团签到 = function ()
  if findTap('cmp_国服骑士团签到') then
    wait(function ()
      stap({509,35})
      if findOne('cmp_国服左上骑士团') then return 1 end
    end)
  end
end

path.社团捐赠 = function ()
  wait(function ()
    stap({1090,414})
    if findOne("500|130|FFFFFF,513|121|FFFFFF,520|132|FFFFFF,544|128|FFFFFF,538|137|FFFFFF") then
      return 1
    end
  end)
  -- 金币
  -- 勇气证据
  -- 都捐赠
  local giveType = current_task.社团捐赠类型
  if giveType == 0 then
    findTap('cmp_国服金币捐赠')
  elseif giveType == 1 then
    findTap('cmp_国服勇气证据捐赠')
  elseif giveType == 2 then
    findTap('cmp_国服金币捐赠')
    wait(function ()
      stap({515,40})
      if findOne('cmp_国服左上骑士团') then return 1 end
    end)
    findTap('cmp_国服勇气证据捐赠')
  end
  wait(function ()
    stap({515,40})
    if findOne('cmp_国服左上骑士团') then return 1 end
  end)
end

path.社团奖励 = function ()
  wait(function ()
    stap({1114,698})
    if findOne('cmp_国服骑士团每周任务', {sim = 1}) then return 1 end
  end)
  -- 上方小红点处理, 这个识别的mul_...可以公用
  if findTap('mul_国服每日每周小红球', {rg = {437,140,987,212}, sim = .98}) then
    wait(function ()
      stap({600,81})
      if findOne('cmp_国服骑士团每周任务', {sim = 1}) then return 1 end
    end)
  end
  -- 中间领取处理
  -- 好似只用滑动一下, 也就是只有两页
  for i=1,2 do
    wait(function ()
      if findTap('mul_国服骑士团任务领取', {rg = {866,255,990,722}}) then
        wait(function ()
          stap({424,30})
          if findOne('cmp_国服骑士团每周任务', {sim = 1}) then return 1 end
        end)
      else
        return 1
      end
    end)
    if i == 1 then sswipe({574,674}, {574,287}) ssleep(.5) end
  end
end

-- finish
path.刷书签 = function (rest)
  rest = rest or 0
  setNumberConfig("is_refresh_book_tag", 1)
  path.游戏首页()
  wait(function ()
    stap(point.秘密商店)
    if not findOne('cmp_国服主页Rank') then return 1 end
  end)
  log('进入神秘商店')
  untilAppear('cmp_国服神秘商店立即更新')
  untilAppear('cmp_国服神秘商店第一个商品') ssleep(.5)
  -- 开始挂机刷新书签了
  -- mul_国服神秘商店友情书签
  -- mul_国服神秘商店誓约书签
  local target = {}
  local g1 = sgetNumberConfig("g1", 0)
  local g2 = sgetNumberConfig("g2", 0)
  local g3 = sgetNumberConfig("g3", 0)
  if current_task['神秘奖牌'] then table.insert(target, 'mul_国服神秘商店神秘奖牌') end 
  if current_task['誓约书签'] then table.insert(target, 'mul_国服神秘商店誓约书签') end
  if current_task['友情书签'] then table.insert(target, 'mul_国服神秘商店友情书签') end
  local refreshCount = current_task['更新次数'] or 334
  local enoughResources = true
  local msg
  for i=1,refreshCount do
    if i > rest then
      for i=1,4 do
      -- 可能会出现乱买, 相似度不够高?
      -- 第一排神秘会漏掉? todo 
      local pos, countTarget = findOne(target, {rg = {538,30,677,720}}) -- 532,48,675,723
      if pos then
        local newRg = {1147, pos[2] - 80, 1226, pos[2] + 80}
        untilTap('mul_国服神秘商店购买', {rg = newRg})
        untilTap('cmp_国服神秘商店购买')
        -- 统计获得物品次数
        if countTarget == 'mul_国服神秘商店神秘奖牌' then
          g1 = g1 + 1
          setNumberConfig("g1", g1)
        elseif countTarget == 'mul_国服神秘商店誓约书签' then
          g2 = g2 + 1
          setNumberConfig("g2", g2)
        elseif countTarget == 'mul_国服神秘商店友情书签' then
          g3 = g3 + 1
          setNumberConfig("g3", g3)
        end
        -- 等待购买特效消失
        wait(function ()
          if not longAppearMomentDisAppear({'cmp_国服神秘商店立即更新', 'cmp_国服神秘商店购买资源不足', 'cmp_国服一般商店'}, nil, nil, 1.5) then return 1 end
        end)
      end
      -- 资源是否耗尽
      wait(function ()
        local r1, r2 = findOne({'cmp_国服神秘商店购买资源不足', 'cmp_国服神秘商店立即更新', 'cmp_国服一般商店'}, {sim = 1})
        if r2 == 'cmp_国服神秘商店立即更新' then return 1 end
        if r2 == 'cmp_国服神秘商店购买资源不足' or r2 == 'cmp_国服一般商店' then enoughResources = false return 1 end
      end)
      -- 写死判定，可能会connection导致滑动失效
      if i == 2 and enoughResources then 
        wait(function ()
          sswipe({858,578}, {858,150})
          ssleep(1)
          if findOne({'cmp_国服神秘商店第二个商品', 'cmp_国服神秘商店第三个商品', 'cmp_国服神秘商店第四个商品'}) then return 1 end
        end)
      end
      end
      msg = '刷新次数: '..i..'(神秘奖牌: '..g1..'*5, 誓约书签: '..g2..'*5, 友情书签: '..g3..'*5)'
      if not enoughResources then 
        log('资源耗尽!')
        slog('资源耗尽!')
        -- untilTap('cmp_国服神秘商店取消')
        path.游戏首页()
        break
      end
      -- 刷新次数: 1 (神秘奖牌: 5*5, 誓约书签: 10*5, 友情书签: 20*5)
      log(msg)
      slog(msg, nil, true)
      -- 如果网络不好会导致两次点击, 改成 sim = 1
      untilTap('cmp_国服神秘商店立即更新', {sim = 1})
      untilTap('cmp_国服神秘商店购买确认')
      untilAppear('cmp_国服神秘商店第一个商品') ssleep(.5)
      setNumberConfig("exception_count", 1)
    end
    setNumberConfig("refresh_book_tag_count", i)
  end
  setNumberConfig("refresh_book_tag_count", 0)
  setNumberConfig("is_refresh_book_tag", 0)
  slog(msg)
end

path.回到主页 = function ()
  local t
  wait(function ()
    if findOne('cmp_国服主页Rank') then 
      if not t then t = time() end
      if t and time() - t > 1000 then return 1 end
      return
    end
    -- findTap({'cmp_国服派遣任务重新进行'}, {tapInterval = 0})
    if t then t = time() end
    -- stap(point.退出)
    back()
  end, .6)
end

-- finish
path.刷竞技场 = function ()
  wait(function ()
    stap(point.竞技场)
    ssleep(1)
    if not findOne('cmp_国服主页Rank') then return 1 end
  end)
  untilTap('cmp_国服竞技场')
  local r1, r2
  wait(function ()
    stap({386,17})
    r1, r2 = findOne({'cmp_国服竞技场配置防御队', 'cmp_国服竞技场每周结算时间', 'cmp_国服竞技场每周排名奖励'})
    if r1 then return 1 end
  end)
  if r2 == 'cmp_国服竞技场每周结算时间' then
    slog('竞技场每周结算时间退出')
    return
  end
  if r2 == 'cmp_国服竞技场每周排名奖励' then
    slog('竞技场获取每周排名奖励')
    local rankIndex = current_task['竞技场每周奖励'] or 0
    local pos = point.国服竞技场每周奖励[rankIndex + 1]
    wait(function ()
      stap(pos)
      if findOne(point.国服竞技场每周奖励判定[rankIndex + 1]) then return 1 end
    end)
    untilTap('cmp_国服竞技场领取每周奖励')
  end
  log('进入竞技场')
  -- 竞技策略
  -- 个人积分
  local privatePoints = untilAppear('ocr_国服竞技场个人积分', {keyword = {'积分', '积', '分'}})
  privatePoints = getArenaPoints(privatePoints[1].text)
  -- log(privatePoints)
  -- 交战对手切换
  wait(function ()
    stap({1108,116})
    if findOne({'mul_国服竞技场挑战', 'mul_国服竞技场再次挑战', 'mul_国服竞技场已挑战过对手'}, {rg = {879,146,990,686}}) then 
      ssleep(1) return 1 
    end
  end, .5)
  
  -- 刷新对手到达次数
  local refreshCount = current_task['交战剩余次数']
  -- 叶子购买票
  local buyTicket = current_task['叶子买票']
  -- 购买切换挑战对手次数，金币
  local buyChangeCount = true
  wait(function ()
    -- 升级可能会卡在这里, 不在下面 path.战斗代理 里面处理, 会导致其他战斗代理出问题
    wait(function ()
      findTap('cmp_国服竞技场挑战升级')
      stap({323,27})
      if findOne('mul_国服竞技场旗帜位置') then return 1 end
    end)
    -- 识别票数
    local ticketFlat = untilAppear('mul_国服竞技场旗帜位置', {rg = {275,8,1042,67}})
    local tmpV, ticket = untilAppear({'mul_国服竞技场票数0', 'mul_国服竞技场票数1', 'mul_国服竞技场票数2', 
                                      'mul_国服竞技场票数3', 'mul_国服竞技场票数4', 'mul_国服竞技场票数5'}, 
                                      {rg = {ticketFlat[1], 5, ticketFlat[1] + 80 , 60}})
    ticket = getArenaPoints(ticket)
    log('所剩票数: '..ticket)
    if ticket == 0 then
      log('票数耗尽')
      -- 是否使用叶子兑换5张票
      -- 是否使用砖石兑换5张票 暂不支持
      if buyTicket then
        wait(function ()
          stap({699,32})
          if findOne('cmp_国服竞技场购买票页面') then return 1 end
        end)
        local tmp, ticketType = untilAppear({'cmp_国服竞技场叶子购买票', 'cmp_国服竞技场砖石购买票'})
        if ticketType == 'cmp_国服竞技场叶子购买票' then 
          log('购票') 
          untilTap('cmp_国服竞技场购买票')
          -- 金币是否够用
          local tmp, v = untilAppear({'cmp_国服神秘商店购买资源不足', 'cmp_国服竞技场配置防御队'})
          if v == 'cmp_国服神秘商店购买资源不足' then log('资源不足') return 1 end
        end
        if ticketType == 'cmp_国服竞技场砖石购买票' then log('取消购票') untilTap('cmp_国服竞技场取消购票') return 1 end
        return
      else
        log('不购票')
        return 1
      end
    end
    -- 敌人积分
    local enemyPointsInfo = untilAppear('ocr_国服竞技场敌人积分')
    -- 过滤非敌人积分; 敌人积分转换成数字
    enemyPointsInfo = table.filter(enemyPointsInfo, function (v) 
      if v.text:find('积分') or v.text:find('积') or v.text:find('分') then
        local tmp, isChallenge = untilAppear({'mul_国服竞技场已挑战过对手', 'mul_国服竞技场挑战', 
                                              'mul_国服竞技场再次挑战'}, {rg = {886, v.t - 50, 990, v.b + 50}})
        if isChallenge == 'mul_国服竞技场挑战' then v.text = getArenaPoints(v.text) return 1 end
       end 
    end)
    -- log(enemyPointsInfo)
    -- 最终需要的: 小于个人积分就行
    local finalPointsInfo = table.filter(enemyPointsInfo, function (v) return v.text < privatePoints end)
    -- 没有小于自己的
    -- 要么手动花费金币刷新，要么等待刷新8分钟
    if #finalPointsInfo == 0 then
      if buyChangeCount then
        local result = untilAppear('ocr_国服刷新挑战', {keyword = {'免费', '剩余时间', '时间', '剩余'}})[1]
        untilTap('ocr_国服刷新挑战')
        if result.text:includes({'剩余时间', '剩余', '时间'}) then
          local availableRefreashCount = math.floor(getArenaPoints(untilAppear('ocr_国服竞技场挑战对手剩余刷新次数')[1].text) / 100)
          if refreshCount == availableRefreashCount or availableRefreashCount == 0 then 
            log('对手更换次数已上限!') 
            untilTap('cmp_国服竞技场取消更换对手') 
            return 1 
          end
        end
        untilTap('cmp_国服竞技场切换对手确定')
        -- 金币是否耗尽
        local tmp, v = untilAppear({'cmp_国服神秘商店购买资源不足', 'cmp_国服竞技场配置防御队'})
        if v == 'cmp_国服神秘商店购买资源不足' then log('资源不足') untilTap('cmp_国服神秘商店取消') return 1 end
        -- 更新完对手, 开始新的一轮
        return
      else
        log('无低于自己积分')
        return 1
      end
    end
    finalPointsInfo = finalPointsInfo[1]
    untilTap('mul_国服竞技场挑战', {rg = {886, finalPointsInfo.t - 80, 990, finalPointsInfo.b + 80}})
    untilTap('cmp_国服竞技场战斗开始')
    path.战斗代理()
  end, .5, nil, true)
end

-- finish
-- open2x 开启2倍数
-- petSkill 神兽技能
path.战斗代理 = function (isRepeat)
  log('战斗开始')
  -- 开启auto
  if not isRepeat then
    untilAppear('cmp_国服Auto')
    wait(function ()
      stap('cmp_国服Auto')
      ssleep(1)
      if findOne(point.国服AUto成功) then return 1 end
    end)
  end

  wait(function ()
    if findOne('cmp_国服二倍速') then return 1 end
    ssleep(1)
    stap('cmp_国服二倍速')
  end)

  -- 等待结束
  -- 每次限定超时战斗为5分钟
  if not isRepeat then
    wait(function ()
      -- 部分会有一个结束前置页, 直接点击掉
      stap({615,23})
      if findTap({'cmp_国服战斗完成竞技场确定', 'cmp_国服战斗完成确定'}, {tapInterval = 1}) then return 1 end
    end, game_running_capture_interval, 10 * 60)
  else
    local target = {'战斗开始', '确认', '重新进行'}
    local endTarget = {'cmp_国服行动力不足', 'cmp_国服战斗问号', 'cmp_国服背包空间不足'}
    wait(function ()
      if findOne('ocr_国服重复战斗完成', {keyword = {'重复战斗已结束'}}) 
                  and findOne('ocr_国服右下角', {keyword = {'确认'}}) then 
        wait(function ()
          if not findTap('ocr_国服右下角', {keyword = target}) then 
           if findOne(endTarget) then return 1 end 
          end
        end)
        return 1
      end
      if findOne('cmp_国服神兽技能', {sim = .9}) then stap({903,664}) end
    end, game_running_capture_interval, 25 * 7 * 60) -- 25 * 7 (一把7分钟)
  end
  log('战斗代理完成')
end

-- finish
path.领养宠物 = function ()
  if not findOne('cmp_国服宠物小屋红点') then log('无宠物领取') return end
  wait(function ()
    stap(point.宠物小屋)
    ssleep(1)
    if not findOne('cmp_国服主页Rank') then return 1 end
  end)
  untilTap('cmp_国服宠物领养')
  if wait(function ()
    stap('cmp_国服宠物免费领养')
    if not findOne('cmp_国服宠物免费领养') then return 1 end
    if findOne('cmp_国服宠物背包不足') then path.宠物背包清理() return 2 end
  end) == 2 then
    return 2
  end
  -- 免费领取一次
  wait(function ()
    stap({34,151})
    if findOne('cmp_国服宠物领养') then return 1 end
  end)
end

-- finish
path.成就领取 = function ()
  if not findOne({'cmp_国服成就红点', 'cmp_国服成就红点2'}) then log('无成就领取') return 1 end
  wait(function ()
    stap(point.成就)
    ssleep(1)
    if not findOne('cmp_国服主页Rank') then return 1 end
  end)
  untilAppear('cmp_国服声誉总分下方花')
  local target = {'cmp_国服三姐妹日记', 'cmp_国服记忆之根管理院', 'cmp_国服元老院', 'cmp_国服商人联盟', 'cmp_国服特务幻影队'}
  for i,v in pairs(target) do
    local curTarget
    wait(function ()
      stap(v)
      curTarget = findOne('ocr_国服成就类型')
      if curTarget and v:find(curTarget[1].text) then return 1 end
    end)
    -- 三姐妹日记比较特殊
    if v == 'cmp_国服三姐妹日记' then
      local targ = {'cmp_国服每日成就', 'cmp_国服每周成就'}
      local key = {{'每日', '日'}, {'每周', '周'}}
      for i,v in pairs(targ) do
        if findOne(v) then
          -- 切换到 每日/每周点数
          wait(function ()
            stap(v)
            if findOne('ocr_国服每日每周点数', {keyword = key[i]}) then return 1 end
          end)
          untilTap('mul_国服每日每周小红球', {rg = {415,141,946,185}, sim = .98})
          wait(function ()
            stap({574,40})
            if findOne('cmp_国服声誉总分下方花') then return 1 end
          end)
        end
      end
    else
      wait(function ()
        findTap('cmp_国服成就领取绿色')
        if findOne('cmp_国服成就前往灰色') then log(11) return 1 end
        stap({574,40})
      end)
    end
  end
end

-- finish
path.宠物礼盒 = function ()
  if findOne('cmp_国服宠物礼盒') then untilTap('cmp_国服宠物礼盒') else log('无宠物礼盒') end
end

-- finish
path.收取邮件 = function ()
  if not findOne({'cmp_国服邮件', 'cmp_国服邮件2'}) then log('无邮件') return 1 end
  wait(function ()
    stap(point.邮件)
    ssleep(1)
    if not findOne('cmp_国服主页Rank') then return 1 end
  end)
  untilAppear('cmp_国服邮件页面')
  wait(function ()
    stap({911,87})
    if findTap('cmp_国服邮件领取确认蓝底') then return 1 end
  end)
  wait(function ()
    stap({563,85})
    if findOne('cmp_国服邮件页面') then return 1 end
  end)
  -- 部分无法用全部领取的
  wait(function ()
    if not findTap('cmp_国服邮件领取绿底') then return 1 end
    local tmp, target = untilAppear({'cmp_国服邮件收信', 'cmp_国服邮件领取蓝底', 'cmp_国服邮件获得奖励Tip', 
                                     'cmp_国服邮件页面', 'cmp_国服邮件领取英雄确定'})
    if target and target ~= 'cmp_国服邮件页面' then untilTap(target) end
    wait(function ()
      stap({563,85})
      findTap('cmp_国服邮件领取英雄确定')
      if findOne('cmp_国服邮件页面') then ssleep(.5) return 1 end
    end)
  end, 1, 5 * 60, nil, true)
end

-- finish
path.誓约召唤 = function ()
  if not findOne({'cmp_国服召唤小红点'}) then log('无誓约召唤') return 1 end
  wait(function ()
    stap(point.召唤)
    ssleep(1)
    if not findOne('cmp_国服主页Rank') then return 1 end
  end)
  -- 寻找誓约召唤
  local pos, target
  wait(function ()
    sswipe({1141,588}, {1141,100})
    ssleep(1)
    pos = findOne('ocr_国服召唤类型', {keyword = {'誓约召唤', '誓约'}})
    if pos then return 1 end
  end)
  wait(function ()
    stap({pos[1].l, pos[1].t})
    if findOne('cmp_国服10次召唤') then ssleep(1) return 1 end
  end)
  if findTap('cmp_国服免费1次召唤') then untilTap('cmp_国服召唤确认') end
  wait(function ()
    stap({156,659})
    if findOne('cmp_国服10次召唤') then return 1 end
  end)
end

path.圣域收菜 = function ()
  if not findOne({'cmp_国服圣域小红点'}) then log('无需收菜') return 1 end
  wait(function ()
    stap(point.圣域)
    ssleep(1)
    if not findOne('cmp_国服主页Rank') then return 1 end
  end)
  path.圣域生产奖励领取()
  path.圣域精灵之森领取()
end

-- finish
path.圣域生产奖励领取 = function ()
  untilAppear('cmp_国服圣域首页')
  log('欧勒毕斯之心处理')
  wait(function () 
    if findTap('cmp_国服欧勒毕斯之心') then
      return 1
    end
  end, .1, 1)
  wait(function ()
    stap({649,58})
    if findOne('cmp_国服圣域首页') then ssleep(.5) return 1 end
  end)
end

path.圣域精灵之森领取 = function ()
  log('精灵之森处理')
  local target = {'cmp_国服圣域企鹅蛋', 'cmp_国服圣域精灵之泉', 'cmp_国服圣域种植地', 'cmp_国服圣域种植地收获'}
  if findTap('cmp_国服圣域精灵之森小红点') then
    -- untilAppear('cmp_建筑升级状态')
    wait(function ()
      stap({104,100})
      if findOne('cmp_国服圣域企鹅巢穴') then return 1 end
    end)
    for i,v in pairs(target) do
      if wait(function () if findTap(v) then return 1 end end, 0, .5) then
        wait(function ()
          stap({104,100})
          if findOne('cmp_国服圣域企鹅巢穴') then return 1 end
        end)
      end
    end
  end
  path.圣域首页()
end

local number = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9'}
-- todo 
path.圣域指挥总部 = function ()
  log('指挥总部处理')
  local target = '讨伐'
  if findTap('cmp_国服圣域指挥总部小红点') then
    untilAppear('cmp_建筑升级状态')
    wait(function ()
      stap(point.圣域指挥总部任务[target])
      if findOne('ocr_国服圣域指挥总部任务选择', {keyword = {target}}) then return 1 end
    end)
    local dispatchLevel = findOne('ocr_国服派遣任务等级')
    local dispatchLevelSort = {'12', '8', '6', '4', '2', '1', '30'}
    if not dispatchLevel then log('无派遣') return 1 end
    if #dispatchLevel > 1 then
      -- 过滤非派遣等级
      dispatchLevel = table.filter(dispatchLevel, 
                                  function (v) if v.text:includes({'所需时间', '小时', '分', '秒'}) and 
                                  findOne('mul_国服派遣执行', {rg = {890, v.t, 980, v.b + 75}}) then return 1 end end)
      -- 根据设置等级查询优先派遣level
      for i,v in pairs(dispatchLevelSort) do
        local result = table.findv(dispatchLevel, function (val) if val.text:includes({v}) then return 1 end end)
        if result then dispatchLevel = result break end
      end
    end
    untilTap('mul_国服派遣执行', {rg = {890, dispatchLevel.t, 980, dispatchLevel.b + 75}})
    untilAppear('cmp_国服派遣执行任务')
    local needLevel = getArenaPoints(untilAppear('ocr_国服派遣所需等级', {keyword = {'Lw', 'L', 'v', 'w'}})[1].text)
    -- 自己配置英雄名称
  end
end

path.圣域首页 = function ()
  wait(function ()
    if findOne('cmp_国服圣域首页') then ssleep(1) return 1 end
    stap({31,32})
    ssleep(2)
  end)
end

path.友情体力 = function ()
  log('购买体力')
  wait(function ()
    stap(point.商店)
    ssleep(1)
    if not findOne('cmp_国服主页Rank') then return 1 end
  end)
  untilAppear('cmp_国服一般商店')
end

path.净化深渊 = function ()
  
end

path.战斗选择页 = function ()
  wait(function ()
    stap(point.战斗)
    ssleep(1)
    if not findOne('cmp_国服主页Rank') then return 1 end
  end)
  untilAppear('cmp_国服战斗类型页')
  wait(function ()
    stap({280,260})
    if not findOne('cmp_国服迷宫主页', {sim = 1}) then return 1 end
  end)
end

-- 刷图
path.刷图开启 = function ()
  -- 图过滤
  log('开启刷图')
  -- 讨伐
  local passAll = ui_option.战斗类型
  for i,v in pairs(passAll) do
    if current_task[v] then
      path.战斗选择页()
      wait(function ()
        stap(point.战斗模式位置[v])
        if findOne('ocr_国服战斗类型', {keyword = cutStringGetBinWord(v)}) then return 1 end
      end)
      if path[v]() ~= 0 then
        slog(v..'完成')
      else
        slog(v..'未完成')
      end
      path.游戏首页()
    end
  end
end

-- 跑图模式1
-- 讨伐 精灵祭坛
-- 834,686 834,147
-- typeTarget: mul_国服双足飞龙
-- levelTarget: 13
-- fightCount: 10
path.通用刷图模式1 = function (typeTarget, levelTarget, fightCount)
  local p
  local key = {'阶段', '祭坛', '区域', '讨伐'}
  -- 关卡
  for i=1,3 do
    if wait(function ()
      if findTap(typeTarget, {rg = point.国服战斗类型区域, sim = .9}) then return 1 end
      swipeEndStop({834,686}, {834,300}, .3)
      ssleep(1)
    end, 1, 5) then
      break
    else
      sswipe({835,300}, {835,2000})
      ssleep(1)
    end
    if i == 3 then slog('关卡可能未到开启时间') return 0 end
  end
  untilAppear('mul_国服短选择队伍')

  -- 确定滑动到最上层
  wait(function ()
    if findOne('ocr_国服战斗级别', {keyword = {'1阶', '初级', '区域1'}}) then return 1 end
    sswipe({835,100}, {835,3000})
    ssleep(.5)
    p = findOne('mul_国服级别光圈')
    if p then point.ocr_国服战斗级别 = {p[1] - 100, p[2] - 130, p[1] + 100, p[2]} p = {p[1], p[2] + 50} end
  end)
  -- 遍历级别
  local newTextVal
  -- 新值重复次数
  local newTextValReCount = 0
  wait(function ()
    local curTextVal
    wait(function () curTextVal = findOne('ocr_国服战斗级别', {keyword = key}) end, 0, .5)
    if curTextVal then curTextVal = curTextVal[1].text end
    if curTextVal and curTextVal:find(levelTarget) then return 1 end
    if not newTextVal then
      newTextVal = curTextVal
      newTextValReCount = newTextValReCount + 1
    else
      if newTextVal == curTextVal then 
        newTextValReCount = newTextValReCount + 1
      else
        newTextVal = curTextVal
        newTextValReCount = 0
      end
      if newTextValReCount == 3 then
        sswipe({835,100}, {835,3000})
        ssleep(1)
        newTextVal = nil
        newTextValReCount = 0
      end
    end
    stap(p)
    p = findOne('mul_国服级别光圈')
    if p then point.ocr_国服战斗级别 = {p[1] - 100, p[2] - 130, p[1] + 100, p[2]} p = {p[1], p[2] + 50} end
  end, 1, 5 * 60)

  -- 0 表示此图并未打过
  local selectGroup
  local temp_other_ssleep_interval = other_ssleep_interval
  other_ssleep_interval = 2
  if not wait(function ()
    if findTap('ocr_国服右下角', {keyword = {'选择队', '选择'}}) then return 1 end
  end, .1, 8) then
    return 0
  end
  temp_other_ssleep_interval = temp_other_ssleep_interval

  untilAppear('ocr_国服右下角', {keyword = {'战斗开始'}})
  local greenPos
  if not wait(function ()
    greenPos = findOne('mul_国服是否可自动挂机', {rg = {495,489,776,608}, sim = .9})
    if greenPos then return 1 end
  end, .1, 1) then
    log('未开启自动挂机')
    slog('未开启自动挂机')
    return 0
  else
    wait(function ()
      if findOne('mul_国服重复战斗绿色', {rg = {495,489,776,608}, sim = .9}) then return 1 end
      ssleep(1)
      stap(greenPos)
    end)
  end

  -- untilTap('ocr_国服右下角', {keyword = {'战斗开始'}})

  local pos, noAct
  if wait(function ()
    pos, noAct = findOne({'cmp_国服行动力不足', 'ocr_国服右下角'}, {keyword = {'战斗开始'}})
    if noAct == 'cmp_国服行动力不足' then 
      slog('行动力不足') 
      log('行动力不足!')
      if path.补充体力() == 0 then return 0 end
    end
    if noAct == 'ocr_国服右下角' then stap({pos[1].l, pos[1].t}) end
    if findOne({'cmp_国服二倍速', 'cmp_国服一倍速'}) then return 1 end
  end) == 0  then
    return 0
  end
  local tmp, noAction
  wait(function ()
    tmp, noAction = findOne({'cmp_国服二倍速', 'cmp_国服一倍速'})
    if noAction then return 1 end
  end)

  local staticTarget = {'cmp_国服二倍速', 'cmp_国服行动力不足', 'cmp_国服一倍速', 'cmp_国服背包空间不足'}

  for i=1,fightCount do
    path.战斗代理(true) 

    wait(function ()
      -- 疲劳问题
      wait(function ()
        tmp, noAction = findOne(staticTarget)
        if noAction then return 1 end
      end)
      if noAction == 'cmp_国服行动力不足' then 
        slog('行动力不足') 
        log('行动力不足!')
        if path.补充体力() == 0 then return 0 end
      end
      -- 判定背包类型
      if noAction == 'cmp_国服背包空间不足' then
        slog('清理背包空间')
        log('清理背包空间!')
        local bagSpaceType
        local bagKey = {'英雄', '装备', '神器'}
        wait(function ()
          bagSpaceType = findOne('ocr_背包满类型', {keyword = bagKey})
          if bagSpaceType then
            bagSpaceType = bagSpaceType[1].text
            return 1
          end
        end)
        if bagSpaceType:includes({'英雄'}) then
          path.清理英雄背包()
        elseif bagSpaceType:includes({'装备'}) then
          path.清理装备背包()
        elseif bagSpaceType:includes({'神器'}) then
          path.清理神器背包()
        end
        -- 再次点击，可能还会出现背包问题
        wait(function ()
          if findOne('ocr_国服右下角', {keyword = '战斗开始'}) then
            if findOne(staticTarget) then return 1 end
            stap({1150,659})
          end
        end)
      end
      return 1
    end, 1, 5 * 60)

    log('完成次数: '..i)
  end

end

path.补充体力 = function ()
  local energyType = current_task.补充行动力类型
  local targetRg = {352,237,935,456}
  local pos
  if energyType == 2 then slog('不补充行动力') return 0 end
  if energyType == 0 then
    if not wait(function ()
      pos = findOne('mul_国服行动力叶子', {rg = targetRg})
      if pos then stap(pos) return 1 end
    end, .1, 3) then
      slog('未能补充行动力')
      return 0
    end
  end
  if energyType == 1 then
    -- 存在叶子
    -- 不存在叶子
    if not wait(function ()
      pos = findOne({'mul_国服行动力叶子', 'mul_国服行动力砖石'}, {rg = targetRg})
      if pos then stap(pos) return 1 end
    end) then
      slog('未能补充行动力')
      return 0
    end
  end
  -- 点击确认
  -- 可能有bug, 如果叶子和砖石都没有了
  -- untilTap('cmp_国服竞技场购买票')
  if not wait(function ()
    if findTap('cmp_国服竞技场购买票') then return 1 end
  end, .1, 8) then
    slog('购买行动力失败')
    return 0
  end
  return 1
end

-- 跑图模式2
path.通用刷图模式2 = function ()
  
end

-- 跑图
path.讨伐 = function ()
  local type = 'mul_国服'..getUIRealValue('讨伐关卡类型', '讨伐类型')
  local level = getUIRealValue('讨伐级别', '讨伐级别')
  local fc = current_task.讨伐次数
  return path.通用刷图模式1(type, level, fc)
end

path.精灵祭坛 = function ()
  local type = 'mul_国服'..getUIRealValue('精灵祭坛关卡类型', '精灵祭坛类型')..'精灵'
  local level = getUIRealValue('精灵祭坛级别', '精灵祭坛级别')
  local fc = current_task.精灵祭坛次数
  return path.通用刷图模式1(type, level, fc)
end

path.净化深渊 = function ()
  wait(function ()
    stap(point.战斗)
    ssleep(1)
    if not findOne('cmp_国服主页Rank') then return 1 end
  end)
  path.战斗选择页()
  wait(function ()
    stap(point.战斗模式位置['深渊'])
    if findOne('ocr_国服战斗类型', {keyword = cutStringGetBinWord('深渊')}) then return 1 end
  end)
  if findTap('cmp_国服深渊净化') then
    untilTap('cmp_国服深渊净化确认')
  end
end

path.宠物背包清理 = function ()
  wait(function ()
    stap({1160,668})
    if findOne('cmp_国服宠物自动补满') then
      return 1
    end
  end)

  wait(function ()
    stap('cmp_国服宠物自动补满')
    ssleep(1)
    if findOne('cmp_国服设置自动填充目标') then return 1 end
  end)

  path.过滤背包选择(ui_option.宠物级别, 'cmp_国服宠物')
  -- 特殊造型
  wait(function ()
    if findOne('cmp_国服不包含特点造型宠物') then return 1 end
    stap('cmp_国服不包含特点造型宠物')
  end)

  wait(function ()
    stap({995,657})
    if not findOne('cmp_国服设置自动填充目标') then
      return 1
    end
  end)

  -- 释放宠物
  untilTap('cmp_国服释放宠物')
  untilTap('cmp_国服邮件领取确认蓝底')
end

path.清理装备背包 = function ()
  wait(function ()
    if findOne('cmp_国服背包装备自动选择') then
      return 1
    end
    stap({1081,157})
  end)
  wait(function ()
    if findOne('mul_国服背包绿钩') then
      return 1
    end
    stap('cmp_国服背包装备自动选择')
  end)
  path.过滤背包选择(ui_option.装备类型, 'cmp_国服')
  path.过滤背包选择(ui_option.装备等级, 'cmp_国服')
  path.过滤背包选择(ui_option.装备强化等级, 'cmp_国服')

  -- 武器类型很奇怪, 我大号里武器并又没满，但是没有这几个选项(可能是背包没有慢的原因)
  -- test
  local weaponType = {
    '185|231|00CB64',
    '185|284|00CB64',
    '185|336|00CB64',
    '185|389|00CB64',
    '185|444|00CB64',
    '186|496|00CB64',
  }

  for i,v in pairs(weaponType) do
    local pos = string.split(v, '|')
    pos = {tonumber(pos[1]), tonumber(pos[2])}
    wait(function ()
      if findOne(v) then return 1 end
      stap(pos)
    end)
  end

  wait(function ()
    if findOne('cmp_国服背包装备自动选择') then
      return 1
    end
    stap({334,90})
  end)

  untilTap('cmp_国服装备出售')
  untilTap('cmp_国服邮件领取确认蓝底')
  wait(function ()
    if findOne('ocr_国服右下角', {keyword = '战斗开始'}) then
      return 1
    end
    stap({486,17})
  end)
end

path.清理英雄背包 = function ()
  wait(function ()
    stap({1019,666})
    if findOne('cmp_国服传送英雄') then return 1 end
  end)

  wait(function ()
    stap({1081,89})
    ssleep(1)
    if findOne('715|210|44C8FD,715|260|45CBFE,715|312|44C8FD') then
      return 1
    end
  end)
  -- 过滤等级
  path.过滤背包选择(ui_option.英雄等级, 'cmp_国服英雄')

  -- 特殊设置
  local specialSetting = {
    '883|605|00CB64', -- 隐藏收藏英雄
    '883|657|00CB64', -- 隐藏亲密度10
    '587|657|00CB64', -- 隐藏MAX等级
  }
  for i,v in pairs(specialSetting) do
    local pos = string.split(v, '|')
    pos = {tonumber(pos[1]), tonumber(pos[2])}
    wait(function ()
      if findOne(v) then return 1 end
      stap(pos)
    end)
  end
  
  wait(function ()
    stap({548,34})
    if findOne('cmp_国服传送英雄') then return 1 end
  end)

  wait(function ()
    if longDisappearMomentTap("1052|242|7E411F", nil, nil, 1) or findOne('714|543|41C2FC') then
      return 1
    end
    stap({1121,273})
  end)

  wait(function ()
    stap({548,34})
    if findOne('cmp_国服传送英雄') then return 1 end
  end)

  untilTap('cmp_国服传送英雄')
  untilTap('cmp_国服邮件领取确认蓝底')
  path.跳转('ocr_国服右下角', {keyword = '战斗开始'})
end

path.清理神器背包 = function ()
  wait(function ()
    if findOne('cmp_国服背包装备自动选择') then
      return 1
    end
    stap({1081,157})
  end)
  wait(function ()
    if findOne('mul_国服背包绿钩') then
      return 1
    end
    stap('cmp_国服背包装备自动选择')
  end)
  path.过滤背包选择(ui_option.神器星级, 'cmp_国服神器')
  path.过滤背包选择(ui_option.神器强化, 'cmp_国服神器强化')

  untilTap('cmp_国服神器出售')
  untilTap('cmp_国服邮件领取确认蓝底')
  path.跳转('ocr_国服右下角', {keyword = '战斗开始'})
end
-- 过滤等级或者类型
-- level：级别table
-- target: 目标前缀
path.过滤背包选择 = function (level, target)
  for i,v in pairs(level) do
    local target = target..v
    if current_task[v] then
      wait(function ()
        if findOne(target) then return 1 end
        stap(target)
      end)
    else
      wait(function ()
        if not findOne(target) then
          return 1
        end
        stap(target)
      end)
    end
  end
end

path.跳转 = function (target, config)
  wait(function ()
    if not longAppearMomentDisAppear(target, config, nil, .5) then
      return 1
    end
    back()
  end, 1, 5 * 60)
end