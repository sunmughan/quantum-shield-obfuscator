-- Lua Code Obfuscator
-- Supports Lua 5.1, 5.2, 5.3, 5.4 and LuaJIT

local crypto = require('crypto') or {}
local bit = require('bit') or require('bit32') or {}
local ffi = pcall(require, 'ffi') and require('ffi') or nil

-- Fallback crypto implementation if crypto module not available
if not crypto.encrypt then
    crypto.encrypt = function(data, key, algorithm)
        -- Simple XOR encryption as fallback
        local result = {}
        local keyLen = #key
        for i = 1, #data do
            local keyChar = key:byte((i - 1) % keyLen + 1)
            local dataChar = data:byte(i)
            table.insert(result, string.char(bit.bxor and bit.bxor(dataChar, keyChar) or (dataChar + keyChar) % 256))
        end
        return table.concat(result)
    end
end

-- Fallback bit operations if bit module not available
if not bit.bxor then
    bit.bxor = function(a, b)
        local result = 0
        local bitval = 1
        while a > 0 or b > 0 do
            if (a % 2) ~= (b % 2) then
                result = result + bitval
            end
            bitval = bitval * 2
            a = math.floor(a / 2)
            b = math.floor(b / 2)
        end
        return result
    end
end

local LuaProcessor = {}
LuaProcessor.__index = LuaProcessor

function LuaProcessor:new(options)
    local self = setmetatable({}, LuaProcessor)
    
    self.options = options or {}
    self.identifierMap = {}
    self.stringMap = {}
    self.encryptedStrings = {}
    
    if not self.options.encryptionKey then
        self.options.encryptionKey = 'default_encryption_key_32_chars_'
    end
    
    -- Lua reserved keywords
    self.reservedKeywords = {
        ['and'] = true, ['break'] = true, ['do'] = true, ['else'] = true,
        ['elseif'] = true, ['end'] = true, ['false'] = true, ['for'] = true,
        ['function'] = true, ['goto'] = true, ['if'] = true, ['in'] = true,
        ['local'] = true, ['nil'] = true, ['not'] = true, ['or'] = true,
        ['repeat'] = true, ['return'] = true, ['then'] = true, ['true'] = true,
        ['until'] = true, ['while'] = true
    }
    
    -- Standard Lua functions and libraries
    self.stdFunctions = {
        ['_G'] = true, ['_VERSION'] = true, ['assert'] = true, ['collectgarbage'] = true,
        ['dofile'] = true, ['error'] = true, ['getfenv'] = true, ['getmetatable'] = true,
        ['ipairs'] = true, ['load'] = true, ['loadfile'] = true, ['loadstring'] = true,
        ['module'] = true, ['next'] = true, ['pairs'] = true, ['pcall'] = true,
        ['print'] = true, ['rawequal'] = true, ['rawget'] = true, ['rawlen'] = true,
        ['rawset'] = true, ['require'] = true, ['select'] = true, ['setfenv'] = true,
        ['setmetatable'] = true, ['tonumber'] = true, ['tostring'] = true, ['type'] = true,
        ['unpack'] = true, ['xpcall'] = true,
        -- String library
        ['string'] = true, ['byte'] = true, ['char'] = true, ['dump'] = true,
        ['find'] = true, ['format'] = true, ['gmatch'] = true, ['gsub'] = true,
        ['len'] = true, ['lower'] = true, ['match'] = true, ['rep'] = true,
        ['reverse'] = true, ['sub'] = true, ['upper'] = true,
        -- Table library
        ['table'] = true, ['concat'] = true, ['insert'] = true, ['maxn'] = true,
        ['remove'] = true, ['sort'] = true, ['pack'] = true, ['unpack'] = true,
        -- Math library
        ['math'] = true, ['abs'] = true, ['acos'] = true, ['asin'] = true,
        ['atan'] = true, ['atan2'] = true, ['ceil'] = true, ['cos'] = true,
        ['cosh'] = true, ['deg'] = true, ['exp'] = true, ['floor'] = true,
        ['fmod'] = true, ['frexp'] = true, ['huge'] = true, ['ldexp'] = true,
        ['log'] = true, ['log10'] = true, ['max'] = true, ['min'] = true,
        ['modf'] = true, ['pi'] = true, ['pow'] = true, ['rad'] = true,
        ['random'] = true, ['randomseed'] = true, ['sin'] = true, ['sinh'] = true,
        ['sqrt'] = true, ['tan'] = true, ['tanh'] = true,
        -- IO library
        ['io'] = true, ['close'] = true, ['flush'] = true, ['input'] = true,
        ['lines'] = true, ['open'] = true, ['output'] = true, ['popen'] = true,
        ['read'] = true, ['stderr'] = true, ['stdin'] = true, ['stdout'] = true,
        ['tmpfile'] = true, ['write'] = true,
        -- OS library
        ['os'] = true, ['clock'] = true, ['date'] = true, ['difftime'] = true,
        ['execute'] = true, ['exit'] = true, ['getenv'] = true, ['remove'] = true,
        ['rename'] = true, ['setlocale'] = true, ['time'] = true, ['tmpname'] = true,
        -- Package library
        ['package'] = true, ['config'] = true, ['cpath'] = true, ['loaded'] = true,
        ['loadlib'] = true, ['path'] = true, ['preload'] = true, ['searchers'] = true,
        ['searchpath'] = true, ['seeall'] = true,
        -- Coroutine library
        ['coroutine'] = true, ['create'] = true, ['resume'] = true, ['running'] = true,
        ['status'] = true, ['wrap'] = true, ['yield'] = true,
        -- Debug library
        ['debug'] = true, ['getfenv'] = true, ['gethook'] = true, ['getinfo'] = true,
        ['getlocal'] = true, ['getmetatable'] = true, ['getregistry'] = true,
        ['getupvalue'] = true, ['setfenv'] = true, ['sethook'] = true, ['setlocal'] = true,
        ['setmetatable'] = true, ['setupvalue'] = true, ['traceback'] = true,
        ['upvalueid'] = true, ['upvaluejoin'] = true
    }
    
    -- Game engine specific functions (Love2D, Corona SDK, etc.)
    self.gameEngineFunctions = {
        -- Love2D
        ['love'] = true, ['conf'] = true, ['draw'] = true, ['errhand'] = true,
        ['focus'] = true, ['keypressed'] = true, ['keyreleased'] = true,
        ['load'] = true, ['lowmemory'] = true, ['mousefocus'] = true,
        ['mousemoved'] = true, ['mousepressed'] = true, ['mousereleased'] = true,
        ['quit'] = true, ['resize'] = true, ['run'] = true, ['textedited'] = true,
        ['textinput'] = true, ['threaderror'] = true, ['touchmoved'] = true,
        ['touchpressed'] = true, ['touchreleased'] = true, ['update'] = true,
        ['visible'] = true, ['wheelmoved'] = true,
        -- Corona SDK
        ['display'] = true, ['newRect'] = true, ['newCircle'] = true, ['newText'] = true,
        ['newImage'] = true, ['newImageRect'] = true, ['newGroup'] = true,
        ['timer'] = true, ['performWithDelay'] = true, ['cancel'] = true,
        ['transition'] = true, ['to'] = true, ['from'] = true, ['cancel'] = true,
        ['pause'] = true, ['resume'] = true, ['pauseAll'] = true, ['resumeAll'] = true,
        ['cancelAll'] = true, ['Runtime'] = true, ['addEventListener'] = true,
        ['removeEventListener'] = true, ['dispatchEvent'] = true,
        -- Defold
        ['go'] = true, ['msg'] = true, ['gui'] = true, ['sprite'] = true,
        ['sound'] = true, ['particlefx'] = true, ['physics'] = true,
        ['render'] = true, ['resource'] = true, ['sys'] = true, ['vmath'] = true
    }
    
    return self
end

function LuaProcessor:encryptString(plaintext, key)
    if crypto.encrypt then
        return crypto.encrypt(plaintext, key, 'aes256')
    else
        -- Fallback XOR encryption
        local result = {}
        local keyLen = #key
        for i = 1, #plaintext do
            local keyChar = key:byte((i - 1) % keyLen + 1)
            local dataChar = plaintext:byte(i)
            table.insert(result, string.char(bit.bxor(dataChar, keyChar)))
        end
        return table.concat(result)
    end
end

function LuaProcessor:generateObfuscatedName()
    local charset = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
    local length = math.random(8, 15)
    
    local result = {}
    
    -- First character must be a letter
    table.insert(result, charset:sub(math.random(1, #charset), math.random(1, #charset)))
    
    -- Remaining characters can be letters or numbers
    local fullCharset = charset .. '0123456789'
    for i = 2, length do
        table.insert(result, fullCharset:sub(math.random(1, #fullCharset), math.random(1, #fullCharset)))
    end
    
    return table.concat(result)
end

function LuaProcessor:isReservedIdentifier(identifier)
    return self.reservedKeywords[identifier] or 
           self.stdFunctions[identifier] or 
           self.gameEngineFunctions[identifier]
end

function LuaProcessor:encryptStrings(code, key)
    local result = {}
    
    -- Add decryption utility
    local decryptUtility = [[
-- String decryption utility
local function decryptString(encrypted, key)
    if crypto and crypto.decrypt then
        return crypto.decrypt(encrypted, key, 'aes256')
    else
        -- Fallback XOR decryption
        local result = {}
        local keyLen = #key
        for i = 1, #encrypted do
            local keyChar = key:byte((i - 1) % keyLen + 1)
            local dataChar = encrypted:byte(i)
            table.insert(result, string.char(bit.bxor and bit.bxor(dataChar, keyChar) or (dataChar + keyChar) % 256))
        end
        return table.concat(result)
    end
end

]]
    
    table.insert(result, decryptUtility)
    
    -- Find and encrypt string literals
    local stringIndex = 0
    local lastPos = 1
    
    -- Pattern to match string literals (both single and double quotes)
    for startPos, quote, content, endPos in code:gmatch('()(["\'])(.-)%2()') do
        -- Add code before the string
        table.insert(result, code:sub(lastPos, startPos - 1))
        
        local encrypted = self:encryptString(content, key)
        if encrypted and #encrypted > 0 then
            local varName = '_str_' .. stringIndex
            stringIndex = stringIndex + 1
            
            table.insert(self.encryptedStrings, 
                'local ' .. varName .. ' = decryptString("' .. 
                encrypted:gsub('"', '\\"'):gsub('\n', '\\n'):gsub('\r', '\\r') .. 
                '", "' .. key .. '")')
            
            table.insert(result, varName)
        else
            table.insert(result, quote .. content .. quote)
        end
        
        lastPos = endPos
    end
    
    -- Add remaining code
    table.insert(result, code:sub(lastPos))
    
    -- Combine string declarations with the result
    local finalResult = table.concat(self.encryptedStrings, '\n') .. '\n' .. table.concat(result)
    return finalResult
end

function LuaProcessor:obfuscateIdentifiers(code)
    -- Find all identifiers
    local identifiersToObfuscate = {}
    
    for identifier in code:gmatch('[a-zA-Z_][a-zA-Z0-9_]*') do
        if not self:isReservedIdentifier(identifier) and #identifier > 1 then
            identifiersToObfuscate[identifier] = true
        end
    end
    
    -- Generate obfuscated names
    for identifier in pairs(identifiersToObfuscate) do
        if not self.identifierMap[identifier] then
            self.identifierMap[identifier] = self:generateObfuscatedName()
        end
    end
    
    -- Replace identifiers
    local result = code
    for original, obfuscated in pairs(self.identifierMap) do
        -- Use word boundary pattern to avoid partial replacements
        local pattern = '\\b' .. original:gsub('([%^%$%(%)%%%.%[%]%*%+%-%?])', '%%%1') .. '\\b'
        result = result:gsub(pattern, obfuscated)
    end
    
    return result
end

function LuaProcessor:addControlFlowObfuscation(code)
    -- Convert if-then-else to more complex structures
    local result = code
    
    -- Convert simple if statements to switch-like structures using tables
    result = result:gsub('if%s+(.-)%s+then%s+(.-)%s+end', function(condition, body)
        local switchVar = '_sw' .. math.random(1000, 9999)
        local replacement = 'local ' .. switchVar .. ' = (' .. condition .. ') and 1 or 0\n'
        replacement = replacement .. 'local _actions = {[1] = function() ' .. body .. ' end, [0] = function() end}\n'
        replacement = replacement .. '_actions[' .. switchVar .. ']()'
        return replacement
    end)
    
    -- Convert if-then-else statements
    result = result:gsub('if%s+(.-)%s+then%s+(.-)%s+else%s+(.-)%s+end', function(condition, ifBody, elseBody)
        local switchVar = '_sw' .. math.random(1000, 9999)
        local replacement = 'local ' .. switchVar .. ' = (' .. condition .. ') and 1 or 0\n'
        replacement = replacement .. 'local _actions = {[1] = function() ' .. ifBody .. ' end, [0] = function() ' .. elseBody .. ' end}\n'
        replacement = replacement .. '_actions[' .. switchVar .. ']()'
        return replacement
    end)
    
    return result
end

function LuaProcessor:addDeadCode(code)
    local deadCodeSnippets = {
        'local _dummy1 = math.random(1, 100)\n',
        'local _dummy2 = os.time() % 256\n',
        'if _dummy1 > 200 then print("Never executed") end\n',
        'for _i = 1, 0 do _dummy2 = _dummy2 + 1 end\n',
        'local _dummy_table = {}\n',
        'local _dummy_func = function() return math.random() end\n'
    }
    
    local result = {}
    local lines = {}
    
    -- Split code into lines
    for line in code:gmatch('[^\n]*') do
        table.insert(lines, line)
    end
    
    local insertions = 0
    for i, line in ipairs(lines) do
        table.insert(result, line)
        
        -- Insert dead code after function definitions or control structures
        if (line:match('function') or line:match('if%s+') or line:match('for%s+') or line:match('while%s+')) and insertions < 3 then
            local deadCode = deadCodeSnippets[math.random(1, #deadCodeSnippets)]
            table.insert(result, deadCode:sub(1, -2)) -- Remove trailing newline
            insertions = insertions + 1
        end
    end
    
    return table.concat(result, '\n')
end

function LuaProcessor:addAntiDebugging(code)
    local antiDebugCode = [[
-- Anti-debugging measures for Lua
local function antiDebugCheck()
    -- Check for common debugging variables
    if _G.debug and _G.debug.getinfo then
        local info = debug.getinfo(1, 'S')
        if info and info.what == 'C' then
            -- Possible debugger attachment
            os.exit(1)
        end
    end
    
    -- Check for common Lua debuggers
    local suspiciousModules = {
        'mobdebug', 'debugger', 'luadebug', 'remdebug', 'clidebugger'
    }
    
    for _, module in ipairs(suspiciousModules) do
        if package.loaded[module] then
            os.exit(1)
        end
    end
    
    -- Timing check
    local start = os.clock()
    local dummy = 0
    for i = 1, 1000 do
        dummy = dummy + i
    end
    local elapsed = os.clock() - start
    
    if elapsed > 0.01 then -- 10ms
        os.exit(1)
    end
    
    -- Check for environment manipulation
    if _G._DEBUG or _G.DEBUG or _G.__DEBUG__ then
        os.exit(1)
    end
    
    -- Check for common reverse engineering tools
    local suspiciousGlobals = {
        'cheat', 'hack', 'trainer', 'inject', 'hook', 'patch'
    }
    
    for _, global in ipairs(suspiciousGlobals) do
        if _G[global] then
            os.exit(1)
        end
    end
    
    -- Check for file system access (potential script extraction)
    if io and io.open then
        local testFile = io.open('debug_test_' .. os.time(), 'w')
        if testFile then
            testFile:close()
            os.remove('debug_test_' .. os.time())
        else
            -- File system access restricted, might be sandboxed
            -- This could be normal or suspicious depending on context
        end
    end
    
    -- Check for coroutine manipulation
    if coroutine and coroutine.running then
        local co, main = coroutine.running()
        if not main then
            -- Running in a coroutine, might be suspicious
            -- Uncomment if needed: os.exit(1)
        end
    end
end

]]
    
    local result = antiDebugCode .. code
    
    -- Insert anti-debug calls at the beginning of functions
    result = result:gsub('(function%s+[^(]*%([^)]*%))', '%1\n    antiDebugCheck()')
    result = result:gsub('(local%s+function%s+[^(]*%([^)]*%))', '%1\n    antiDebugCheck()')
    
    -- Insert at the beginning of main code
    result = 'antiDebugCheck()\n' .. result
    
    return result
end

function LuaProcessor:addFunctionObfuscation(code)
    -- Obfuscate function names
    local result = code
    
    -- Find function definitions
    result = result:gsub('function%s+([a-zA-Z_][a-zA-Z0-9_]*)%s*%(', function(funcName)
        if not self:isReservedIdentifier(funcName) then
            local obfuscatedName = '_F' .. self:generateObfuscatedName():sub(1, 8)
            self.identifierMap[funcName] = obfuscatedName
            return 'function ' .. obfuscatedName .. '('
        end
        return 'function ' .. funcName .. '('
    end)
    
    -- Find local function definitions
    result = result:gsub('local%s+function%s+([a-zA-Z_][a-zA-Z0-9_]*)%s*%(', function(funcName)
        if not self:isReservedIdentifier(funcName) then
            local obfuscatedName = '_LF' .. self:generateObfuscatedName():sub(1, 7)
            self.identifierMap[funcName] = obfuscatedName
            return 'local function ' .. obfuscatedName .. '('
        end
        return 'local function ' .. funcName .. '('
    end)
    
    return result
end

function LuaProcessor:addTableObfuscation(code)
    -- Obfuscate table field access
    local result = code
    
    -- Convert dot notation to bracket notation with obfuscated strings
    result = result:gsub('([a-zA-Z_][a-zA-Z0-9_]*)%.([a-zA-Z_][a-zA-Z0-9_]*)', function(table, field)
        if not self:isReservedIdentifier(field) then
            return table .. '["' .. field .. '"]'
        end
        return table .. '.' .. field
    end)
    
    return result
end

function LuaProcessor:process(code, processingOptions)
    processingOptions = processingOptions or {}
    local key = processingOptions.key or self.options.encryptionKey
    
    local result = code
    
    -- Apply Lua-specific obfuscations
    result = self:encryptStrings(result, key)
    result = self:addFunctionObfuscation(result)
    result = self:addTableObfuscation(result)
    result = self:obfuscateIdentifiers(result)
    result = self:addControlFlowObfuscation(result)
    result = self:addDeadCode(result)
    result = self:addAntiDebugging(result)
    
    return result
end

-- Export for use as module
if _G then
    _G.LuaProcessor = LuaProcessor
end

-- Main function for command-line usage
if arg and arg[0] and arg[0]:match('LuaProcessor%.lua$') then
    if #arg < 1 then
        print('Usage: lua LuaProcessor.lua <input_file> [options]')
        os.exit(1)
    end
    
    local inputPath = arg[1]
    local file = io.open(inputPath, 'r')
    
    if not file then
        print('Error: Could not open file ' .. inputPath)
        os.exit(1)
    end
    
    local code = file:read('*all')
    file:close()
    
    -- Initialize processor with options
    local options = {
        encryptionKey = 'default_encryption_key_32_chars_'
    }
    
    local processor = LuaProcessor:new(options)
    
    -- Process the code
    local obfuscated = processor:process(code)
    
    -- Output result
    print(obfuscated)
end

return LuaProcessor