--! Nanocore Internal UI
--! Version: 3.8
--! Copyright (c) 2024 ttwiz_z



--? Script Hider

pcall(function()
    local _script_ = script
    if _script_ then
        script = nil
        _script_.Parent = nil
        _script_ = nil
        getfenv().script = nil
        for _ = 0, 1 do
            getfenv(_).script = nil
        end
    end
end)


--? Services

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")


--? Constants

local Player = Players.LocalPlayer

local ExecutorTweenInfo = TweenInfo.new(0.075)
local StrokeTweenInfo = TweenInfo.new(0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

local ButtonHover = Color3.fromRGB(120, 120, 120)
local ButtonDown = Color3.fromRGB(170, 170, 170)


--? Instances

local Executor = Instance.new("CanvasGroup")
local UICorner = Instance.new("UICorner")
local Title = Instance.new("TextLabel")
local UICorner_2 = Instance.new("UICorner")
local Editor = Instance.new("Frame")
local Code = Instance.new("ScrollingFrame")
local Content = Instance.new("TextBox")
local UIPadding = Instance.new("UIPadding")
local Buttons = Instance.new("Frame")
local UIListLayout = Instance.new("UIListLayout")
local Execute = Instance.new("TextButton")
local UIStroke = Instance.new("UIStroke")
local UICorner_3 = Instance.new("UICorner")
local Clear = Instance.new("TextButton")
local UIStroke_2 = Instance.new("UIStroke")
local UICorner_4 = Instance.new("UICorner")
local UIStroke_3 = Instance.new("UIStroke")


--? Functions

local function RandomString()
    local Length = math.random(10, 20)
    local Array = {}
    for Index = 1, Length do
        Array[Index] = string.char(math.random(32, 126))
    end
    return table.concat(Array)
end

local function AutoRename(Object)
    while task.wait() do
        if Object and typeof(Object) == "Instance" and Object.Parent then
            Object.Name = RandomString()
        else
            break
        end
    end
end

local function Tween(Object, TweenInfo, Properties)
    if Object and typeof(Object) == "Instance" and TweenInfo and typeof(TweenInfo) == "TweenInfo" and Properties and type(Properties) == "table" then
        TweenService:Create(Object, TweenInfo, Properties):Play()
    end
end

local function SmoothDrag(Object)
    if Object and type(Object) == "userdata" then
        local Toggle, Input, Start, StartPosition
        local function Update(Key)
            local Delta = Key.Position - Start
            local NewPosition = UDim2.new(StartPosition.X.Scale, StartPosition.X.Offset + Delta.X, StartPosition.Y.Scale, StartPosition.Y.Offset + Delta.Y)
            Tween(Object, ExecutorTweenInfo, {Position = NewPosition})
        end
        Object.InputBegan:Connect(function(NewInput)
            if (NewInput.UserInputType == Enum.UserInputType.MouseButton1 or NewInput.UserInputType == Enum.UserInputType.Touch) and not UserInputService:GetFocusedTextBox() then
                Toggle = true
                Start = NewInput.Position
                StartPosition = Object.Position
                NewInput.Changed:Connect(function()
                    if NewInput.UserInputState == Enum.UserInputState.End then
                        Toggle = false
                    end
                end)
            end
        end)
        Object.InputChanged:Connect(function(NewInput)
            if NewInput.UserInputType == Enum.UserInputType.MouseMovement or NewInput.UserInputType == Enum.UserInputType.Touch then
                Input = NewInput
            end
        end)
        UserInputService.InputChanged:Connect(function(NewInput)
            if NewInput == Input and Toggle then
                Update(NewInput)
            end
        end)
    end
end


--? NanocoreVM

--# selene: allow(incorrect_standard_library_use, multiple_statements, shadowing, unused_variable, empty_if, divide_by_zero, unbalanced_assignments)
--[[

  lopcodes.lua
  Lua 5 virtual machine opcodes in Lua
  This file is part of Yueliang.

  Copyright (c) 2006 Kein-Hong Man <khman@users.sf.net>
  The COPYRIGHT file describes the conditions
  under which this software may be distributed.

  See the ChangeLog for more information.

]]

--[[
-- Notes:
-- * an Instruction is a table with OP, A, B, C, Bx elements; this
--   makes the code easy to follow and should allow instruction handling
--   to work with doubles and ints
-- * WARNING luaP:Instruction outputs instructions encoded in little-
--   endian form and field size and positions are hard-coded
--
-- Not implemented:
-- *
--
-- Added:
-- * luaP:CREATE_Inst(c): create an inst from a number (for OP_SETLIST)
-- * luaP:Instruction(i): convert field elements to a 4-char string
-- * luaP:DecodeInst(x): convert 4-char string into field elements
--
-- Changed in 5.1.x:
-- * POS_OP added, instruction field positions changed
-- * some symbol names may have changed, e.g. LUAI_BITSINT
-- * new operators for RK indices: BITRK, ISK(x), INDEXK(r), RKASK(x)
-- * OP_MOD, OP_LEN is new
-- * OP_TEST is now OP_TESTSET, OP_TEST is new
-- * OP_FORLOOP, OP_TFORLOOP adjusted, OP_FORPREP is new
-- * OP_TFORPREP deleted
-- * OP_SETLIST and OP_SETLISTO merged and extended
-- * OP_VARARG is new
-- * many changes to implementation of OpMode data
]]

local luaP = {}

--[[
===========================================================================
  We assume that instructions are unsigned numbers.
  All instructions have an opcode in the first 6 bits.
  Instructions can have the following fields:
        'A' : 8 bits
        'B' : 9 bits
        'C' : 9 bits
        'Bx' : 18 bits ('B' and 'C' together)
        'sBx' : signed Bx

  A signed argument is represented in excess K; that is, the number
  value is the unsigned value minus K. K is exactly the maximum value
  for that argument (so that -max is represented by 0, and +max is
  represented by 2*max), which is half the maximum for the corresponding
  unsigned argument.
===========================================================================
]]

luaP.OpMode = { iABC = 0, iABx = 1, iAsBx = 2 }  -- basic instruction format

------------------------------------------------------------------------
-- size and position of opcode arguments.
-- * WARNING size and position is hard-coded elsewhere in this script
------------------------------------------------------------------------
luaP.SIZE_C  = 9
luaP.SIZE_B  = 9
luaP.SIZE_Bx = luaP.SIZE_C + luaP.SIZE_B
luaP.SIZE_A  = 8

luaP.SIZE_OP = 6

luaP.POS_OP = 0
luaP.POS_A  = luaP.POS_OP + luaP.SIZE_OP
luaP.POS_C  = luaP.POS_A + luaP.SIZE_A
luaP.POS_B  = luaP.POS_C + luaP.SIZE_C
luaP.POS_Bx = luaP.POS_C

------------------------------------------------------------------------
-- limits for opcode arguments.
-- we use (signed) int to manipulate most arguments,
-- so they must fit in LUAI_BITSINT-1 bits (-1 for sign)
------------------------------------------------------------------------
-- removed "#if SIZE_Bx < BITS_INT-1" test, assume this script is
-- running on a Lua VM with double or int as LUA_NUMBER

luaP.MAXARG_Bx  = math.ldexp(1, luaP.SIZE_Bx) - 1
luaP.MAXARG_sBx = math.floor(luaP.MAXARG_Bx / 2)  -- 'sBx' is signed

luaP.MAXARG_A = math.ldexp(1, luaP.SIZE_A) - 1
luaP.MAXARG_B = math.ldexp(1, luaP.SIZE_B) - 1
luaP.MAXARG_C = math.ldexp(1, luaP.SIZE_C) - 1

-- creates a mask with 'n' 1 bits at position 'p'
-- MASK1(n,p) deleted, not required
-- creates a mask with 'n' 0 bits at position 'p'
-- MASK0(n,p) deleted, not required

--[[
  Visual representation for reference:

   31    |    |     |            0      bit position
    +-----+-----+-----+----------+
    |  B  |  C  |  A  |  Opcode  |      iABC format
    +-----+-----+-----+----------+
    -  9  -  9  -  8  -    6     -      field sizes
    +-----+-----+-----+----------+
    |   [s]Bx   |  A  |  Opcode  |      iABx | iAsBx format
    +-----+-----+-----+----------+

]]

------------------------------------------------------------------------
-- the following macros help to manipulate instructions
-- * changed to a table object representation, very clean compared to
--   the [nightmare] alternatives of using a number or a string
-- * Bx is a separate element from B and C, since there is never a need
--   to split Bx in the parser or code generator
------------------------------------------------------------------------

-- these accept or return opcodes in the form of string names
function luaP:GET_OPCODE(i) return self.ROpCode[i.OP] end
function luaP:SET_OPCODE(i, o) i.OP = self.OpCode[o] end

function luaP:GETARG_A(i) return i.A end
function luaP:SETARG_A(i, u) i.A = u end

function luaP:GETARG_B(i) return i.B end
function luaP:SETARG_B(i, b) i.B = b end

function luaP:GETARG_C(i) return i.C end
function luaP:SETARG_C(i, b) i.C = b end

function luaP:GETARG_Bx(i) return i.Bx end
function luaP:SETARG_Bx(i, b) i.Bx = b end

function luaP:GETARG_sBx(i) return i.Bx - self.MAXARG_sBx end
function luaP:SETARG_sBx(i, b) i.Bx = b + self.MAXARG_sBx end

function luaP:CREATE_ABC(o,a,b,c)
    return {OP = self.OpCode[o], A = a, B = b, C = c}
end

function luaP:CREATE_ABx(o,a,bc)
    return {OP = self.OpCode[o], A = a, Bx = bc}
end

------------------------------------------------------------------------
-- create an instruction from a number (for OP_SETLIST)
------------------------------------------------------------------------
function luaP:CREATE_Inst(c)
    local o = c % 64
    c = (c - o) / 64
    local a = c % 256
    c = (c - a) / 256
    return self:CREATE_ABx(o, a, c)
end

------------------------------------------------------------------------
-- returns a 4-char string little-endian encoded form of an instruction
------------------------------------------------------------------------
function luaP:Instruction(i)
    if i.Bx then
        -- change to OP/A/B/C format
        i.C = i.Bx % 512
        i.B = (i.Bx - i.C) / 512
    end
    local I = i.A * 64 + i.OP
    local c0 = I % 256
    I = i.C * 64 + (I - c0) / 256  -- 6 bits of A left
    local c1 = I % 256
    I = i.B * 128 + (I - c1) / 256  -- 7 bits of C left
    local c2 = I % 256
    local c3 = (I - c2) / 256
    return string.char(c0, c1, c2, c3)
end

------------------------------------------------------------------------
-- decodes a 4-char little-endian string into an instruction struct
------------------------------------------------------------------------
function luaP:DecodeInst(x)
    local byte = string.byte
    local i = {}
    local I = byte(x, 1)
    local op = I % 64
    i.OP = op
    I = byte(x, 2) * 4 + (I - op) / 64  -- 2 bits of c0 left
    local a = I % 256
    i.A = a
    I = byte(x, 3) * 4 + (I - a) / 256  -- 2 bits of c1 left
    local c = I % 512
    i.C = c
    i.B = byte(x, 4) * 2 + (I - c) / 512 -- 1 bits of c2 left
    local opmode = self.OpMode[tonumber(string.sub(self.opmodes[op + 1], 7, 7))]
    if opmode ~= "iABC" then
        i.Bx = i.B * 512 + i.C
    end
    return i
end

------------------------------------------------------------------------
-- Macros to operate RK indices
-- * these use arithmetic instead of bit ops
------------------------------------------------------------------------

-- this bit 1 means constant (0 means register)
luaP.BITRK = math.ldexp(1, luaP.SIZE_B - 1)

-- test whether value is a constant
function luaP:ISK(x) return x >= self.BITRK end

-- gets the index of the constant
function luaP:INDEXK(x) return x - self.BITRK end

luaP.MAXINDEXRK = luaP.BITRK - 1

-- code a constant index as a RK value
function luaP:RKASK(x) return x + self.BITRK end

------------------------------------------------------------------------
-- invalid register that fits in 8 bits
------------------------------------------------------------------------
luaP.NO_REG = luaP.MAXARG_A

------------------------------------------------------------------------
-- R(x) - register
-- Kst(x) - constant (in constant table)
-- RK(x) == if ISK(x) then Kst(INDEXK(x)) else R(x)
------------------------------------------------------------------------

------------------------------------------------------------------------
-- grep "ORDER OP" if you change these enums
------------------------------------------------------------------------

--[[
Lua virtual machine opcodes (enum OpCode):
------------------------------------------------------------------------
name          args    description
------------------------------------------------------------------------
OP_MOVE       A B     R(A) := R(B)
OP_LOADK      A Bx    R(A) := Kst(Bx)
OP_LOADBOOL   A B C   R(A) := (Bool)B; if (C) pc++
OP_LOADNIL    A B     R(A) := ... := R(B) := nil
OP_GETUPVAL   A B     R(A) := UpValue[B]
OP_GETGLOBAL  A Bx    R(A) := Gbl[Kst(Bx)]
OP_GETTABLE   A B C   R(A) := R(B)[RK(C)]
OP_SETGLOBAL  A Bx    Gbl[Kst(Bx)] := R(A)
OP_SETUPVAL   A B     UpValue[B] := R(A)
OP_SETTABLE   A B C   R(A)[RK(B)] := RK(C)
OP_NEWTABLE   A B C   R(A) := {} (size = B,C)
OP_SELF       A B C   R(A+1) := R(B); R(A) := R(B)[RK(C)]
OP_ADD        A B C   R(A) := RK(B) + RK(C)
OP_SUB        A B C   R(A) := RK(B) - RK(C)
OP_MUL        A B C   R(A) := RK(B) * RK(C)
OP_DIV        A B C   R(A) := RK(B) / RK(C)
OP_MOD        A B C   R(A) := RK(B) % RK(C)
OP_POW        A B C   R(A) := RK(B) ^ RK(C)
OP_UNM        A B     R(A) := -R(B)
OP_NOT        A B     R(A) := not R(B)
OP_LEN        A B     R(A) := length of R(B)
OP_CONCAT     A B C   R(A) := R(B).. ... ..R(C)
OP_JMP        sBx     pc+=sBx
OP_EQ         A B C   if ((RK(B) == RK(C)) ~= A) then pc++
OP_LT         A B C   if ((RK(B) <  RK(C)) ~= A) then pc++
OP_LE         A B C   if ((RK(B) <= RK(C)) ~= A) then pc++
OP_TEST       A C     if not (R(A) <=> C) then pc++
OP_TESTSET    A B C   if (R(B) <=> C) then R(A) := R(B) else pc++
OP_CALL       A B C   R(A), ... ,R(A+C-2) := R(A)(R(A+1), ... ,R(A+B-1))
OP_TAILCALL   A B C   return R(A)(R(A+1), ... ,R(A+B-1))
OP_RETURN     A B     return R(A), ... ,R(A+B-2)  (see note)
OP_FORLOOP    A sBx   R(A)+=R(A+2);
                      if R(A) <?= R(A+1) then { pc+=sBx; R(A+3)=R(A) }
OP_FORPREP    A sBx   R(A)-=R(A+2); pc+=sBx
OP_TFORLOOP   A C     R(A+3), ... ,R(A+2+C) := R(A)(R(A+1), R(A+2));
                      if R(A+3) ~= nil then R(A+2)=R(A+3) else pc++
OP_SETLIST    A B C   R(A)[(C-1)*FPF+i] := R(A+i), 1 <= i <= B
OP_CLOSE      A       close all variables in the stack up to (>=) R(A)
OP_CLOSURE    A Bx    R(A) := closure(KPROTO[Bx], R(A), ... ,R(A+n))
OP_VARARG     A B     R(A), R(A+1), ..., R(A+B-1) = vararg
]]

luaP.opnames = {}  -- opcode names
luaP.OpCode = {}   -- lookup name -> number
luaP.ROpCode = {}  -- lookup number -> name

------------------------------------------------------------------------
-- ORDER OP
------------------------------------------------------------------------
local i = 0
for v in string.gmatch([[
MOVE LOADK LOADBOOL LOADNIL GETUPVAL
GETGLOBAL GETTABLE SETGLOBAL SETUPVAL SETTABLE
NEWTABLE SELF ADD SUB MUL
DIV MOD POW UNM NOT
LEN CONCAT JMP EQ LT
LE TEST TESTSET CALL TAILCALL
RETURN FORLOOP FORPREP TFORLOOP SETLIST
CLOSE CLOSURE VARARG
]], "%S+") do
    local n = "OP_"..v
    luaP.opnames[i] = v
    luaP.OpCode[n] = i
    luaP.ROpCode[i] = n
    i = i + 1
end
luaP.NUM_OPCODES = i

--[[
===========================================================================
  Notes:
  (*) In OP_CALL, if (B == 0) then B = top. C is the number of returns - 1,
      and can be 0: OP_CALL then sets 'top' to last_result+1, so
      next open instruction (OP_CALL, OP_RETURN, OP_SETLIST) may use 'top'.
  (*) In OP_VARARG, if (B == 0) then use actual number of varargs and
      set top (like in OP_CALL with C == 0).
  (*) In OP_RETURN, if (B == 0) then return up to 'top'
  (*) In OP_SETLIST, if (B == 0) then B = 'top';
      if (C == 0) then next 'instruction' is real C
  (*) For comparisons, A specifies what condition the test should accept
      (true or false).
  (*) All 'skips' (pc++) assume that next instruction is a jump
===========================================================================
]]

--[[
  masks for instruction properties. The format is:
  bits 0-1: op mode
  bits 2-3: C arg mode
  bits 4-5: B arg mode
  bit 6: instruction set register A
  bit 7: operator is a test

  for OpArgMask:
  OpArgN - argument is not used
  OpArgU - argument is used
  OpArgR - argument is a register or a jump offset
  OpArgK - argument is a constant or register/constant
]]

-- was enum OpArgMask
luaP.OpArgMask = { OpArgN = 0, OpArgU = 1, OpArgR = 2, OpArgK = 3 }

------------------------------------------------------------------------
-- e.g. to compare with symbols, luaP:getOpMode(...) == luaP.OpCode.iABC
-- * accepts opcode parameter as strings, e.g. "OP_MOVE"
------------------------------------------------------------------------

function luaP:getOpMode(m)
    return self.opmodes[self.OpCode[m]] % 4
end

function luaP:getBMode(m)
    return math.floor(self.opmodes[self.OpCode[m]] / 16) % 4
end

function luaP:getCMode(m)
    return math.floor(self.opmodes[self.OpCode[m]] / 4) % 4
end

function luaP:testAMode(m)
    return math.floor(self.opmodes[self.OpCode[m]] / 64) % 2
end

function luaP:testTMode(m)
    return math.floor(self.opmodes[self.OpCode[m]] / 128)
end

-- luaP_opnames[] is set above, as the luaP.opnames table

-- number of list items to accumulate before a SETLIST instruction
luaP.LFIELDS_PER_FLUSH = 50

------------------------------------------------------------------------
-- build instruction properties array
-- * deliberately coded to look like the C equivalent
------------------------------------------------------------------------
local function opmode(t, a, b, c, m)
    local luaP = luaP
    return t * 128 + a * 64 +
        luaP.OpArgMask[b] * 16 + luaP.OpArgMask[c] * 4 + luaP.OpMode[m]
end

-- ORDER OP
luaP.opmodes = {
    -- T A B C mode opcode
    opmode(0, 1, "OpArgK", "OpArgN", "iABx"),     -- OP_LOADK
    opmode(0, 1, "OpArgU", "OpArgU", "iABC"),     -- OP_LOADBOOL
    opmode(0, 1, "OpArgR", "OpArgN", "iABC"),     -- OP_LOADNIL
    opmode(0, 1, "OpArgU", "OpArgN", "iABC"),     -- OP_GETUPVAL
    opmode(0, 1, "OpArgK", "OpArgN", "iABx"),     -- OP_GETGLOBAL
    opmode(0, 1, "OpArgR", "OpArgK", "iABC"),     -- OP_GETTABLE
    opmode(0, 0, "OpArgK", "OpArgN", "iABx"),     -- OP_SETGLOBAL
    opmode(0, 0, "OpArgU", "OpArgN", "iABC"),     -- OP_SETUPVAL
    opmode(0, 0, "OpArgK", "OpArgK", "iABC"),     -- OP_SETTABLE
    opmode(0, 1, "OpArgU", "OpArgU", "iABC"),     -- OP_NEWTABLE
    opmode(0, 1, "OpArgR", "OpArgK", "iABC"),     -- OP_SELF
    opmode(0, 1, "OpArgK", "OpArgK", "iABC"),     -- OP_ADD
    opmode(0, 1, "OpArgK", "OpArgK", "iABC"),     -- OP_SUB
    opmode(0, 1, "OpArgK", "OpArgK", "iABC"),     -- OP_MUL
    opmode(0, 1, "OpArgK", "OpArgK", "iABC"),     -- OP_DIV
    opmode(0, 1, "OpArgK", "OpArgK", "iABC"),     -- OP_MOD
    opmode(0, 1, "OpArgK", "OpArgK", "iABC"),     -- OP_POW
    opmode(0, 1, "OpArgR", "OpArgN", "iABC"),     -- OP_UNM
    opmode(0, 1, "OpArgR", "OpArgN", "iABC"),     -- OP_NOT
    opmode(0, 1, "OpArgR", "OpArgN", "iABC"),     -- OP_LEN
    opmode(0, 1, "OpArgR", "OpArgR", "iABC"),     -- OP_CONCAT
    opmode(0, 0, "OpArgR", "OpArgN", "iAsBx"),    -- OP_JMP
    opmode(1, 0, "OpArgK", "OpArgK", "iABC"),     -- OP_EQ
    opmode(1, 0, "OpArgK", "OpArgK", "iABC"),     -- OP_LT
    opmode(1, 0, "OpArgK", "OpArgK", "iABC"),     -- OP_LE
    opmode(1, 1, "OpArgR", "OpArgU", "iABC"),     -- OP_TEST
    opmode(1, 1, "OpArgR", "OpArgU", "iABC"),     -- OP_TESTSET
    opmode(0, 1, "OpArgU", "OpArgU", "iABC"),     -- OP_CALL
    opmode(0, 1, "OpArgU", "OpArgU", "iABC"),     -- OP_TAILCALL
    opmode(0, 0, "OpArgU", "OpArgN", "iABC"),     -- OP_RETURN
    opmode(0, 1, "OpArgR", "OpArgN", "iAsBx"),    -- OP_FORLOOP
    opmode(0, 1, "OpArgR", "OpArgN", "iAsBx"),    -- OP_FORPREP
    opmode(1, 0, "OpArgN", "OpArgU", "iABC"),     -- OP_TFORLOOP
    opmode(0, 0, "OpArgU", "OpArgU", "iABC"),     -- OP_SETLIST
    opmode(0, 0, "OpArgN", "OpArgN", "iABC"),     -- OP_CLOSE
    opmode(0, 1, "OpArgU", "OpArgN", "iABx"),     -- OP_CLOSURE
    opmode(0, 1, "OpArgU", "OpArgN", "iABC"),     -- OP_VARARG
}
-- an awkward way to set a zero-indexed table...
luaP.opmodes[0] =
    opmode(0, 1, "OpArgR", "OpArgN", "iABC")      -- OP_MOVE

--# selene: allow(incorrect_standard_library_use, multiple_statements, shadowing, unused_variable, empty_if, divide_by_zero, unbalanced_assignments)
--[[

  lzio.lua
  Lua buffered streams in Lua
  This file is part of Yueliang.

  Copyright (c) 2005-2006 Kein-Hong Man <khman@users.sf.net>
  The COPYRIGHT file describes the conditions
  under which this software may be distributed.

  See the ChangeLog for more information.

]]

--[[
-- Notes:
-- * EOZ is implemented as a string, "EOZ"
-- * Format of z structure (ZIO)
--     z.n       -- bytes still unread
--     z.p       -- last read position position in buffer
--     z.reader  -- chunk reader function
--     z.data    -- additional data
-- * Current position, p, is now last read index instead of a pointer
--
-- Not implemented:
-- * luaZ_lookahead: used only in lapi.c:lua_load to detect binary chunk
-- * luaZ_read: used only in lundump.c:ezread to read +1 bytes
-- * luaZ_openspace: dropped; let Lua handle buffers as strings (used in
--   lundump.c:LoadString & lvm.c:luaV_concat)
-- * luaZ buffer macros: dropped; buffers are handled as strings
-- * lauxlib.c:getF reader implementation has an extraline flag to
--   skip over a shbang (#!) line, this is not implemented here
--
-- Added:
-- (both of the following are vaguely adapted from lauxlib.c)
-- * luaZ:make_getS: create Reader from a string
-- * luaZ:make_getF: create Reader that reads from a file
--
-- Changed in 5.1.x:
-- * Chunkreader renamed to Reader (ditto with Chunkwriter)
-- * Zio struct: no more name string, added Lua state for reader
--   (however, Yueliang readers do not require a Lua state)
]]

local luaZ = {}

------------------------------------------------------------------------
-- * reader() should return a string, or nil if nothing else to parse.
--   Additional data can be set only during stream initialization
-- * Readers are handled in lauxlib.c, see luaL_load(file|buffer|string)
-- * LUAL_BUFFERSIZE=BUFSIZ=512 in make_getF() (located in luaconf.h)
-- * Original Reader typedef:
--   const char * (*lua_Reader) (lua_State *L, void *ud, size_t *sz);
-- * This Lua chunk reader implementation:
--   returns string or nil, no arguments to function
------------------------------------------------------------------------

------------------------------------------------------------------------
-- create a chunk reader from a source string
------------------------------------------------------------------------
function luaZ:make_getS(buff)
    local b = buff
    return function() -- chunk reader anonymous function here
        if not b then return nil end
        local data = b
        b = nil
        return data
    end
end

------------------------------------------------------------------------
-- create a chunk reader from a source file
------------------------------------------------------------------------
--[[
function luaZ:make_getF(filename)
  local LUAL_BUFFERSIZE = 512
  local h = io.open(filename, "r")
  if not h then return nil end
  return function() -- chunk reader anonymous function here
    if not h or io.type(h) == "closed file" then return nil end
    local buff = h:read(LUAL_BUFFERSIZE)
    if not buff then h:close(); h = nil end
    return buff
  end
end
]]
------------------------------------------------------------------------
-- creates a zio input stream
-- returns the ZIO structure, z
------------------------------------------------------------------------
function luaZ:init(reader, data, name)
    if not reader then return end
    local z = {}
    z.reader = reader
    z.data = data or ""
    z.name = name
    -- set up additional data for reading
    if not data or data == "" then z.n = 0 else z.n = #data end
    z.p = 0
    return z
end

------------------------------------------------------------------------
-- fill up input buffer
------------------------------------------------------------------------
function luaZ:fill(z)
    local buff = z.reader()
    z.data = buff
    if not buff or buff == "" then return "EOZ" end
    z.n, z.p = #buff - 1, 1
    return string.sub(buff, 1, 1)
end

------------------------------------------------------------------------
-- get next character from the input stream
-- * local n, p are used to optimize code generation
------------------------------------------------------------------------
function luaZ:zgetc(z)
    local n, p = z.n, z.p + 1
    if n > 0 then
        z.n, z.p = n - 1, p
        return string.sub(z.data, p, p)
    else
        return self:fill(z)
    end
end

--# selene: allow(incorrect_standard_library_use, multiple_statements, shadowing, unused_variable, empty_if, divide_by_zero, unbalanced_assignments)
--[[

  ldump.lua
  Save precompiled Lua chunks
  This file is part of Yueliang.

  Copyright (c) 2006 Kein-Hong Man <khman@users.sf.net>
  The COPYRIGHT file describes the conditions
  under which this software may be distributed.

  See the ChangeLog for more information.

]]

--[[
-- Notes:
-- * WARNING! byte order (little endian) and data type sizes for header
--   signature values hard-coded; see luaU:header
-- * chunk writer generators are included, see below
-- * one significant difference is that instructions are still in table
--   form (with OP/A/B/C/Bx fields) and luaP:Instruction() is needed to
--   convert them into 4-char strings
--
-- Not implemented:
-- * DumpVar, DumpMem has been removed
-- * DumpVector folded into folded into DumpDebug, DumpCode
--
-- Added:
-- * for convenience, the following two functions have been added:
--   luaU:make_setS: create a chunk writer that writes to a string
--   luaU:make_setF: create a chunk writer that writes to a file
--   (lua.h contains a typedef for lua_Writer/lua_Chunkwriter, and
--    a Lua-based implementation exists, writer() in lstrlib.c)
-- * luaU:ttype(o) (from lobject.h)
-- * for converting number types to its binary equivalent:
--   luaU:from_double(x): encode double value for writing
--   luaU:from_int(x): encode integer value for writing
--     (error checking is limited for these conversion functions)
--     (double conversion does not support denormals or NaNs)
--
-- Changed in 5.1.x:
-- * the dumper was mostly rewritten in Lua 5.1.x, so notes on the
--   differences between 5.0.x and 5.1.x is limited
-- * LUAC_VERSION bumped to 0x51, LUAC_FORMAT added
-- * developer is expected to adjust LUAC_FORMAT in order to identify
--   non-standard binary chunk formats
-- * header signature code is smaller, has been simplified, and is
--   tested as a single unit; its logic is shared with the undumper
-- * no more endian conversion, invalid endianness mean rejection
-- * opcode field sizes are no longer exposed in the header
-- * code moved to front of a prototype, followed by constants
-- * debug information moved to the end of the binary chunk, and the
--   relevant functions folded into a single function
-- * luaU:dump returns a writer status code
-- * chunk writer now implements status code because dumper uses it
-- * luaU:endianness removed
]]

local luaU = {}

-- mark for precompiled code ('<esc>Lua') (from lua.h)
luaU.LUA_SIGNATURE = "\27Lua"

-- constants used by dumper (from lua.h)
luaU.LUA_TNUMBER  = 3
luaU.LUA_TSTRING  = 4
luaU.LUA_TNIL     = 0
luaU.LUA_TBOOLEAN = 1
luaU.LUA_TNONE    = -1

-- constants for header of binary files (from lundump.h)
luaU.LUAC_VERSION    = 0x51     -- this is Lua 5.1
luaU.LUAC_FORMAT     = 0        -- this is the official format
luaU.LUAC_HEADERSIZE = 12       -- size of header of binary files

--[[
-- Additional functions to handle chunk writing
-- * to use make_setS and make_setF, see test_ldump.lua elsewhere
]]

------------------------------------------------------------------------
-- create a chunk writer that writes to a string
-- * returns the writer function and a table containing the string
-- * to get the final result, look in buff.data
------------------------------------------------------------------------
function luaU:make_setS()
    local buff = {}
    buff.data = ""
    local writer =
        function(s, buff)  -- chunk writer
            if not s then return 0 end
            buff.data = buff.data..s
            return 0
        end
    return writer, buff
end

------------------------------------------------------------------------
-- create a chunk writer that writes to a file
-- * returns the writer function and a table containing the file handle
-- * if a nil is passed, then writer should close the open file
------------------------------------------------------------------------

--[[
function luaU:make_setF(filename)
  local buff = {}
        buff.h = io.open(filename, "wb")
  if not buff.h then return nil end
  local writer =
    function(s, buff)  -- chunk writer
      if not buff.h then return 0 end
      if not s then
        if buff.h:close() then return 0 end
      else
        if buff.h:write(s) then return 0 end
      end
      return 1
    end
  return writer, buff
end]]

------------------------------------------------------------------------
-- works like the lobject.h version except that TObject used in these
-- scripts only has a 'value' field, no 'tt' field (native types used)
------------------------------------------------------------------------
function luaU:ttype(o)
    local tt = type(o.value)
    if tt == "number" then return self.LUA_TNUMBER
    elseif tt == "string" then return self.LUA_TSTRING
    elseif tt == "nil" then return self.LUA_TNIL
    elseif tt == "boolean" then return self.LUA_TBOOLEAN
    else
        return self.LUA_TNONE  -- the rest should not appear
    end
end

-----------------------------------------------------------------------
-- converts a IEEE754 double number to an 8-byte little-endian string
-- * luaU:from_double() and luaU:from_int() are adapted from ChunkBake
-- * supports +/- Infinity, but not denormals or NaNs
-----------------------------------------------------------------------
function luaU:from_double(x)
    local function grab_byte(v)
        local c = v % 256
        return (v - c) / 256, string.char(c)
    end
    local sign = 0
    if x < 0 then sign = 1; x = -x end
    local mantissa, exponent = math.frexp(x)
    if x == 0 then -- zero
        mantissa, exponent = 0, 0
    elseif x == 1/0 then
        mantissa, exponent = 0, 2047
    else
        mantissa = (mantissa * 2 - 1) * math.ldexp(0.5, 53)
        exponent = exponent + 1022
    end
    local v, byte = "" -- convert to bytes
    x = math.floor(mantissa)
    for i = 1,6 do
        x, byte = grab_byte(x); v = v..byte -- 47:0
    end
    x, byte = grab_byte(exponent * 16 + x); v = v..byte -- 55:48
    x, byte = grab_byte(sign * 128 + x); v = v..byte -- 63:56
    return v
end

-----------------------------------------------------------------------
-- converts a number to a little-endian 32-bit integer string
-- * input value assumed to not overflow, can be signed/unsigned
-----------------------------------------------------------------------
function luaU:from_int(x)
    local v = ""
    x = math.floor(x)
    if x < 0 then x = 4294967296 + x end  -- ULONG_MAX+1
    for i = 1, 4 do
        local c = x % 256
        v = v..string.char(c); x = math.floor(x / 256)
    end
    return v
end

--[[
-- Functions to make a binary chunk
-- * many functions have the size parameter removed, since output is
--   in the form of a string and some sizes are implicit or hard-coded
]]

--[[
-- struct DumpState:
--   L  -- lua_State (not used in this script)
--   writer  -- lua_Writer (chunk writer function)
--   data  -- void* (chunk writer context or data already written)
--   strip  -- if true, don't write any debug information
--   status  -- if non-zero, an error has occured
]]

------------------------------------------------------------------------
-- dumps a block of bytes
-- * lua_unlock(D.L), lua_lock(D.L) unused
------------------------------------------------------------------------
function luaU:DumpBlock(b, D)
    if D.status == 0 then
        -- lua_unlock(D->L);
        D.status = D.write(b, D.data)
        -- lua_lock(D->L);
    end
end

------------------------------------------------------------------------
-- dumps a char
------------------------------------------------------------------------
function luaU:DumpChar(y, D)
    self:DumpBlock(string.char(y), D)
end

------------------------------------------------------------------------
-- dumps a 32-bit signed or unsigned integer (for int) (hard-coded)
------------------------------------------------------------------------
function luaU:DumpInt(x, D)
    self:DumpBlock(self:from_int(x), D)
end

------------------------------------------------------------------------
-- dumps a lua_Number (hard-coded as a double)
------------------------------------------------------------------------
function luaU:DumpNumber(x, D)
    self:DumpBlock(self:from_double(x), D)
end

------------------------------------------------------------------------
-- dumps a Lua string (size type is hard-coded)
------------------------------------------------------------------------
function luaU:DumpString(s, D)
    if s == nil then
        self:DumpInt(0, D)
    else
        s = s.."\0"  -- include trailing '\0'
        self:DumpInt(#s, D)
        self:DumpBlock(s, D)
    end
end

------------------------------------------------------------------------
-- dumps instruction block from function prototype
------------------------------------------------------------------------
function luaU:DumpCode(f, D)
    local n = f.sizecode
    --was DumpVector
    self:DumpInt(n, D)
    for i = 0, n - 1 do
        self:DumpBlock(luaP:Instruction(f.code[i]), D)
    end
end

------------------------------------------------------------------------
-- dump constant pool from function prototype
-- * bvalue(o), nvalue(o) and rawtsvalue(o) macros removed
------------------------------------------------------------------------
function luaU:DumpConstants(f, D)
    local n = f.sizek
    self:DumpInt(n, D)
    for i = 0, n - 1 do
        local o = f.k[i]  -- TValue
        local tt = self:ttype(o)
        self:DumpChar(tt, D)
        if tt == self.LUA_TNIL then
        elseif tt == self.LUA_TBOOLEAN then
            self:DumpChar(o.value and 1 or 0, D)
        elseif tt == self.LUA_TNUMBER then
            self:DumpNumber(o.value, D)
        elseif tt == self.LUA_TSTRING then
            self:DumpString(o.value, D)
        else
            --lua_assert(0)  -- cannot happen
        end
    end
    n = f.sizep
    self:DumpInt(n, D)
    for i = 0, n - 1 do
        self:DumpFunction(f.p[i], f.source, D)
    end
end

------------------------------------------------------------------------
-- dump debug information
------------------------------------------------------------------------
function luaU:DumpDebug(f, D)
    local n
    n = D.strip and 0 or f.sizelineinfo           -- dump line information
    --was DumpVector
    self:DumpInt(n, D)
    for i = 0, n - 1 do
        self:DumpInt(f.lineinfo[i], D)
    end
    n = D.strip and 0 or f.sizelocvars            -- dump local information
    self:DumpInt(n, D)
    for i = 0, n - 1 do
        self:DumpString(f.locvars[i].varname, D)
        self:DumpInt(f.locvars[i].startpc, D)
        self:DumpInt(f.locvars[i].endpc, D)
    end
    n = D.strip and 0 or f.sizeupvalues           -- dump upvalue information
    self:DumpInt(n, D)
    for i = 0, n - 1 do
        self:DumpString(f.upvalues[i], D)
    end
end

------------------------------------------------------------------------
-- dump child function prototypes from function prototype
------------------------------------------------------------------------
function luaU:DumpFunction(f, p, D)
    local source = f.source
    if source == p or D.strip then source = nil end
    self:DumpString(source, D)
    self:DumpInt(f.lineDefined, D)
    self:DumpInt(f.lastlinedefined, D)
    self:DumpChar(f.nups, D)
    self:DumpChar(f.numparams, D)
    self:DumpChar(f.is_vararg, D)
    self:DumpChar(f.maxstacksize, D)
    self:DumpCode(f, D)
    self:DumpConstants(f, D)
    self:DumpDebug(f, D)
end

------------------------------------------------------------------------
-- dump Lua header section (some sizes hard-coded)
------------------------------------------------------------------------
function luaU:DumpHeader(D)
    local h = self:header()
    assert(#h == self.LUAC_HEADERSIZE) -- fixed buffer now an assert
    self:DumpBlock(h, D)
end

------------------------------------------------------------------------
-- make header (from lundump.c)
-- returns the header string
------------------------------------------------------------------------
function luaU:header()
    local x = 1
    return self.LUA_SIGNATURE..
        string.char(
            self.LUAC_VERSION,
            self.LUAC_FORMAT,
            x,                    -- endianness (1=little)
            4,                    -- sizeof(int)
            4,                    -- sizeof(size_t)
            4,                    -- sizeof(Instruction)
            8,                    -- sizeof(lua_Number)
            0)                    -- is lua_Number integral?
end

------------------------------------------------------------------------
-- dump Lua function as precompiled chunk
-- (lua_State* L, const Proto* f, lua_Writer w, void* data, int strip)
-- * w, data are created from make_setS, make_setF
------------------------------------------------------------------------
function luaU:dump(L, f, w, data, strip)
    local D = {}  -- DumpState
    D.L = L
    D.write = w
    D.data = data
    D.strip = strip
    D.status = 0
    self:DumpHeader(D)
    self:DumpFunction(f, nil, D)
    -- added: for a chunk writer writing to a file, this final call with
    -- nil data is to indicate to the writer to close the file
    D.write(nil, D.data)
    return D.status
end

--# selene: allow(incorrect_standard_library_use, multiple_statements, shadowing, unused_variable, empty_if, divide_by_zero, unbalanced_assignments)
--[[

  llex.lua
  Lua lexical analyzer in Lua
  This file is part of Yueliang.

  Copyright (c) 2005-2006 Kein-Hong Man <khman@users.sf.net>
  The COPYRIGHT file describes the conditions
  under which this software may be distributed.

  See the ChangeLog for more information.

]]

--[[
-- Notes:
-- * intended to 'imitate' llex.c code; performance is not a concern
-- * tokens are strings; code structure largely retained
-- * deleted stuff (compared to llex.c) are noted, comments retained
-- * nextc() returns the currently read character to simplify coding
--   here; next() in llex.c does not return anything
-- * compatibility code is marked with "--#" comments
--
-- Added:
-- * luaX:chunkid (function luaO_chunkid from lobject.c)
-- * luaX:str2d (function luaO_str2d from lobject.c)
-- * luaX.LUA_QS used in luaX:lexerror (from luaconf.h)
-- * luaX.LUA_COMPAT_LSTR in luaX:read_long_string (from luaconf.h)
-- * luaX.MAX_INT used in luaX:inclinenumber (from llimits.h)
--
-- To use the lexer:
-- (1) luaX:init() to initialize the lexer
-- (2) luaX:setinput() to set the input stream to lex
-- (3) call luaX:next() or luaX:luaX:lookahead() to get tokens,
--     until "TK_EOS": luaX:next()
-- * since EOZ is returned as a string, be careful when regexp testing
--
-- Not implemented:
-- * luaX_newstring: not required by this Lua implementation
-- * buffer MAX_SIZET size limit (from llimits.h) test not implemented
--   in the interest of performance
-- * locale-aware number handling is largely redundant as Lua's
--   tonumber() function is already capable of this
--
-- Changed in 5.1.x:
-- * TK_NAME token order moved down
-- * string representation for TK_NAME, TK_NUMBER, TK_STRING changed
-- * token struct renamed to lower case (LS -> ls)
-- * LexState struct: removed nestlevel, added decpoint
-- * error message functions have been greatly simplified
-- * token2string renamed to luaX_tokens, exposed in llex.h
-- * lexer now handles all kinds of newlines, including CRLF
-- * shbang first line handling removed from luaX:setinput;
--   it is now done in lauxlib.c (luaL_loadfile)
-- * next(ls) macro renamed to nextc(ls) due to new luaX_next function
-- * EXTRABUFF and MAXNOCHECK removed due to lexer changes
-- * checkbuffer(ls, len) macro deleted
-- * luaX:read_numeral now has 3 support functions: luaX:trydecpoint,
--   luaX:buffreplace and (luaO_str2d from lobject.c) luaX:str2d
-- * luaX:read_numeral is now more promiscuous in slurping characters;
--   hexadecimal numbers was added, locale-aware decimal points too
-- * luaX:skip_sep is new; used by luaX:read_long_string
-- * luaX:read_long_string handles new-style long blocks, with some
--   optional compatibility code
-- * luaX:llex: parts changed to support new-style long blocks
-- * luaX:llex: readname functionality has been folded in
-- * luaX:llex: removed test for control characters
--
]]

local luaX = {}

-- FIRST_RESERVED is not required as tokens are manipulated as strings
-- TOKEN_LEN deleted; maximum length of a reserved word not needed

------------------------------------------------------------------------
-- "ORDER RESERVED" deleted; enumeration in one place: luaX.RESERVED
------------------------------------------------------------------------

-- terminal symbols denoted by reserved words: TK_AND to TK_WHILE
-- other terminal symbols: TK_NAME to TK_EOS
luaX.RESERVED = [[
TK_AND and
TK_BREAK break
TK_CONTINUE continue
TK_DO do
TK_ELSE else
TK_ELSEIF elseif
TK_END end
TK_FALSE false
TK_FOR for
TK_FUNCTION function
TK_IF if
TK_IN in
TK_LOCAL local
TK_NIL nil
TK_NOT not
TK_OR or
TK_REPEAT repeat
TK_RETURN return
TK_THEN then
TK_TRUE true
TK_UNTIL until
TK_WHILE while
TK_ASSIGN_ADD +=
TK_ASSIGN_SUB -=
TK_ASSIGN_MUL *=
TK_ASSIGN_DIV /=
TK_ASSIGN_MOD %=
TK_ASSIGN_POW ^=
TK_ASSIGN_CONCAT ..=
TK_CONCAT ..
TK_DOTS ...
TK_EQ ==
TK_GE >=
TK_LE <=
TK_NE ~=
TK_NAME <name>
TK_NUMBER <number>
TK_STRING <string>
TK_EOS <eof>]]

-- NUM_RESERVED is not required; number of reserved words

--[[
-- Instead of passing seminfo, the Token struct (e.g. ls.t) is passed
-- so that lexer functions can use its table element, ls.t.seminfo
--
-- SemInfo (struct no longer needed, a mixed-type value is used)
--
-- Token (struct of ls.t and ls.lookahead):
--   token  -- token symbol
--   seminfo  -- semantics information
--
-- LexState (struct of ls; ls is initialized by luaX:setinput):
--   current  -- current character (charint)
--   linenumber  -- input line counter
--   lastline  -- line of last token 'consumed'
--   t  -- current token (table: struct Token)
--   lookahead  -- look ahead token (table: struct Token)
--   fs  -- 'FuncState' is private to the parser
--   L -- LuaState
--   z  -- input stream
--   buff  -- buffer for tokens
--   source  -- current source name
--   decpoint -- locale decimal point
--   nestlevel  -- level of nested non-terminals
]]

-- luaX.tokens (was luaX_tokens) is now a hash; see luaX:init

luaX.MAXSRC = 80
luaX.MAX_INT = 2147483645       -- constants from elsewhere (see above)
luaX.LUA_QS = "'%s'"
luaX.LUA_COMPAT_LSTR = 1
--luaX.MAX_SIZET = 4294967293

------------------------------------------------------------------------
-- initialize lexer
-- * original luaX_init has code to create and register token strings
-- * luaX.tokens: TK_* -> token
-- * luaX.enums:  token -> TK_* (used in luaX:llex)
------------------------------------------------------------------------
function luaX:init()
    local tokens, enums = {}, {}
    for v in string.gmatch(self.RESERVED, "[^\n]+") do
        local _, _, tok, str = string.find(v, "(%S+)%s+(%S+)")
        tokens[tok] = str
        enums[str] = tok
    end
    self.tokens = tokens
    self.enums = enums
end

------------------------------------------------------------------------
-- returns a suitably-formatted chunk name or id
-- * from lobject.c, used in llex.c and ldebug.c
-- * the result, out, is returned (was first argument)
------------------------------------------------------------------------
function luaX:chunkid(source, bufflen)
    local out
    local first = string.sub(source, 1, 1)
    if first == "=" then
        out = string.sub(source, 2, bufflen)  -- remove first char
    else  -- out = "source", or "...source"
        if first == "@" then
            source = string.sub(source, 2)  -- skip the '@'
            bufflen = bufflen - #" '...' "
            local l = #source
            out = ""
            if l > bufflen then
                source = string.sub(source, 1 + l - bufflen)  -- get last part of file name
                out = out.."..."
            end
            out = out..source
        else  -- out = [string "string"]
            local len = string.find(source, "[\n\r]")  -- stop at first newline
            len = len and (len - 1) or #source
            bufflen = bufflen - #(" [string \"...\"] ")
            if len > bufflen then len = bufflen end
            out = "[string \""
            if len < #source then  -- must truncate?
                out = out..string.sub(source, 1, len).."..."
            else
                out = out..source
            end
            out = out.."\"]"
        end
    end
    return out
end

--[[
-- Support functions for lexer
-- * all lexer errors eventually reaches lexerror:
     syntaxerror -> lexerror
]]

------------------------------------------------------------------------
-- look up token and return keyword if found (also called by parser)
------------------------------------------------------------------------
function luaX:token2str(ls, token)
    if string.sub(token, 1, 3) ~= "TK_" then
        if string.find(token, "%c") then
            return string.format("char(%d)", string.byte(token))
        end
        return token
    else
    end
    return self.tokens[token]
end

------------------------------------------------------------------------
-- throws a lexer error
-- * txtToken has been made local to luaX:lexerror
-- * can't communicate LUA_ERRSYNTAX, so it is unimplemented
------------------------------------------------------------------------
function luaX:lexerror(ls, msg, token)
    local function txtToken(ls, token)
        if token == "TK_NAME" or
            token == "TK_STRING" or
            token == "TK_NUMBER" then
            return ls.buff
        else
            return self:token2str(ls, token)
        end
    end
    local buff = self:chunkid(ls.source, self.MAXSRC)
    local msg = string.format("%s:%d: %s", buff, ls.linenumber, msg)
    if token then
        msg = string.format("%s near "..self.LUA_QS, msg, txtToken(ls, token))
    end
    -- luaD_throw(ls->L, LUA_ERRSYNTAX)
    error(msg)
end

------------------------------------------------------------------------
-- throws a syntax error (mainly called by parser)
-- * ls.t.token has to be set by the function calling luaX:llex
--   (see luaX:next and luaX:lookahead elsewhere in this file)
------------------------------------------------------------------------
function luaX:syntaxerror(ls, msg)
    self:lexerror(ls, msg, ls.t.token)
end

------------------------------------------------------------------------
-- move on to next line
------------------------------------------------------------------------
function luaX:currIsNewline(ls)
    return ls.current == "\n" or ls.current == "\r"
end

function luaX:inclinenumber(ls)
    local old = ls.current
    -- lua_assert(currIsNewline(ls))
    self:nextc(ls)  -- skip '\n' or '\r'
    if self:currIsNewline(ls) and ls.current ~= old then
        self:nextc(ls)  -- skip '\n\r' or '\r\n'
    end
    ls.linenumber = ls.linenumber + 1
    if ls.linenumber >= self.MAX_INT then
        self:syntaxerror(ls, "chunk has too many lines")
    end
end

------------------------------------------------------------------------
-- initializes an input stream for lexing
-- * if ls (the lexer state) is passed as a table, then it is filled in,
--   otherwise it has to be retrieved as a return value
-- * LUA_MINBUFFER not used; buffer handling not required any more
------------------------------------------------------------------------
function luaX:setinput(L, ls, z, source)
    if not ls then ls = {} end  -- create struct
    if not ls.lookahead then ls.lookahead = {} end
    if not ls.t then ls.t = {} end
    ls.decpoint = "."
    ls.L = L
    ls.lookahead.token = "TK_EOS"  -- no look-ahead token
    ls.z = z
    ls.fs = nil
    ls.linenumber = 1
    ls.lastline = 1
    ls.source = source
    self:nextc(ls)  -- read first char
end

--[[
-- LEXICAL ANALYZER
]]

------------------------------------------------------------------------
-- checks if current character read is found in the set 'set'
------------------------------------------------------------------------
function luaX:check_next(ls, set)
    if not string.find(set, ls.current, 1, 1) then
        return false
    end
    self:save_and_next(ls)
    return true
end

------------------------------------------------------------------------
-- retrieve next token, checking the lookahead buffer if necessary
-- * note that the macro next(ls) in llex.c is now luaX:nextc
-- * utilized used in lparser.c (various places)
------------------------------------------------------------------------
function luaX:next(ls)
    ls.lastline = ls.linenumber
    if ls.lookahead.token ~= "TK_EOS" then  -- is there a look-ahead token?
        -- this must be copy-by-value
        ls.t.seminfo = ls.lookahead.seminfo  -- use this one
        ls.t.token = ls.lookahead.token
        ls.lookahead.token = "TK_EOS"  -- and discharge it
    else
        ls.t.token = self:llex(ls, ls.t)  -- read next token
    end
end

------------------------------------------------------------------------
-- fill in the lookahead buffer
-- * utilized used in lparser.c:constructor
------------------------------------------------------------------------
function luaX:lookahead(ls)
    -- lua_assert(ls.lookahead.token == "TK_EOS")
    ls.lookahead.token = self:llex(ls, ls.lookahead)
end

------------------------------------------------------------------------
-- gets the next character and returns it
-- * this is the next() macro in llex.c; see notes at the beginning
------------------------------------------------------------------------
function luaX:nextc(ls)
    local c = luaZ:zgetc(ls.z)
    ls.current = c
    return c
end

------------------------------------------------------------------------
-- saves the given character into the token buffer
-- * buffer handling code removed, not used in this implementation
-- * test for maximum token buffer length not used, makes things faster
------------------------------------------------------------------------

function luaX:save(ls, c)
    local buff = ls.buff
    -- if you want to use this, please uncomment luaX.MAX_SIZET further up
    --if #buff > self.MAX_SIZET then
    --  self:lexerror(ls, "lexical element too long")
    --end
    ls.buff = buff..c
end

------------------------------------------------------------------------
-- save current character into token buffer, grabs next character
-- * like luaX:nextc, returns the character read for convenience
------------------------------------------------------------------------
function luaX:save_and_next(ls)
    self:save(ls, ls.current)
    return self:nextc(ls)
end

------------------------------------------------------------------------
-- LUA_NUMBER
-- * luaX:read_numeral is the main lexer function to read a number
-- * luaX:str2d, luaX:buffreplace, luaX:trydecpoint are support functions
------------------------------------------------------------------------

------------------------------------------------------------------------
-- string to number converter (was luaO_str2d from lobject.c)
-- * returns the number, nil if fails (originally returns a boolean)
-- * conversion function originally lua_str2number(s,p), a macro which
--   maps to the strtod() function by default (from luaconf.h)
-- * ccuser44 was here to add support for binary intiger constants and
--   intiger decimal seperators
------------------------------------------------------------------------
function luaX:str2d(s)
    -- Support for Luau decimal seperators for integer literals
    if string.match(string.lower(s), "[^b%da-f_]_") or string.match(string.lower(s), "_[^%da-f_]") then
        return nil
    end
    s = string.gsub(s, "_", "")

    local result = tonumber(s)
    if result then return result end
    -- conversion failed

    if string.lower(string.sub(s, 1, 2)) == "0x" then  -- maybe an hexadecimal constant?
        result = tonumber(s, 16)
        if result then return result end  -- most common case
        -- Was: invalid trailing characters?
        -- In C, this function then skips over trailing spaces.
        -- true is returned if nothing else is found except for spaces.
        -- If there is still something else, then it returns a false.
        -- All this is not necessary using Lua's tonumber.
    elseif string.lower(string.sub(s, 1, 2)) == "0b" then  -- binary intiger constants
        if string.match(string.sub(s, 3), "[^01]") then
            return nil
        end

        local bin = string.reverse(string.sub(s, 3))
        local sum = 0

        for i = 1, string.len(bin) do
            local num = string.sub(bin, i, i) == "1" and 1 or 0
            sum = sum + num * math.pow(2, i - 1)
        end

        return sum
    end
    return nil
end

------------------------------------------------------------------------
-- single-character replacement, for locale-aware decimal points
------------------------------------------------------------------------
function luaX:buffreplace(ls, from, to)
    local result, buff = "", ls.buff
    for p = 1, #buff do
        local c = string.sub(buff, p, p)
        if c == from then c = to end
        result = result..c
    end
    ls.buff = result
end

------------------------------------------------------------------------
-- Attempt to convert a number by translating '.' decimal points to
-- the decimal point character used by the current locale. This is not
-- needed in Yueliang as Lua's tonumber() is already locale-aware.
-- Instead, the code is here in case the user implements localeconv().
------------------------------------------------------------------------
function luaX:trydecpoint(ls, Token)
    -- format error: try to update decimal point separator
    local old = ls.decpoint
    -- translate the following to Lua if you implement localeconv():
    -- struct lconv *cv = localeconv();
    -- ls->decpoint = (cv ? cv->decimal_point[0] : '.');
    self:buffreplace(ls, old, ls.decpoint)  -- try updated decimal separator
    local seminfo = self:str2d(ls.buff)
    Token.seminfo = seminfo
    if not seminfo then
        -- format error with correct decimal point: no more options
        self:buffreplace(ls, ls.decpoint, ".")  -- undo change (for error message)
        self:lexerror(ls, "malformed number", "TK_NUMBER")
    end
end

------------------------------------------------------------------------
-- main number conversion function
-- * "^%w$" needed in the scan in order to detect "EOZ"
------------------------------------------------------------------------
function luaX:read_numeral(ls, Token)
    -- lua_assert(string.find(ls.current, "%d"))
    repeat
        self:save_and_next(ls)
    until string.find(ls.current, "%D") and ls.current ~= "."
    if self:check_next(ls, "Ee") then  -- 'E'?
        self:check_next(ls, "+-")  -- optional exponent sign
    end
    while string.find(ls.current, "^%w$") or ls.current == "_" do
        self:save_and_next(ls)
    end
    self:buffreplace(ls, ".", ls.decpoint)  -- follow locale for decimal point
    local seminfo = self:str2d(ls.buff)
    Token.seminfo = seminfo
    if not seminfo then  -- format error?
        self:trydecpoint(ls, Token) -- try to update decimal point separator
    end
end

------------------------------------------------------------------------
-- count separators ("=") in a long string delimiter
-- * used by luaX:read_long_string
------------------------------------------------------------------------
function luaX:skip_sep(ls)
    local count = 0
    local s = ls.current
    -- lua_assert(s == "[" or s == "]")
    self:save_and_next(ls)
    while ls.current == "=" do
        self:save_and_next(ls)
        count = count + 1
    end
    return (ls.current == s) and count or (-count) - 1
end

------------------------------------------------------------------------
-- reads a long string or long comment
------------------------------------------------------------------------
function luaX:read_long_string(ls, Token, sep)
    local cont = 0
    self:save_and_next(ls)  -- skip 2nd '['
    if self:currIsNewline(ls) then  -- string starts with a newline?
        self:inclinenumber(ls)  -- skip it
    end
    while true do
        local c = ls.current
        if c == "EOZ" then
            self:lexerror(ls, Token and "unfinished long string" or
                "unfinished long comment", "TK_EOS")
        elseif c == "[" then
            --# compatibility code start
            if self.LUA_COMPAT_LSTR then
                if self:skip_sep(ls) == sep then
                    self:save_and_next(ls)  -- skip 2nd '['
                    cont = cont + 1
                    --# compatibility code start
                    if self.LUA_COMPAT_LSTR == 1 then
                        if sep == 0 then
                            self:lexerror(ls, "nesting of [[...]] is deprecated", "[")
                        end
                    end
                    --# compatibility code end
                end
            end
            --# compatibility code end
        elseif c == "]" then
            if self:skip_sep(ls) == sep then
                self:save_and_next(ls)  -- skip 2nd ']'
                --# compatibility code start
                if self.LUA_COMPAT_LSTR and self.LUA_COMPAT_LSTR == 2 then
                    cont = cont - 1
                    if sep == 0 and cont >= 0 then break end
                end
                --# compatibility code end
                break
            end
        elseif self:currIsNewline(ls) then
            self:save(ls, "\n")
            self:inclinenumber(ls)
            if not Token then ls.buff = "" end -- avoid wasting space
        else  -- default
            if Token then
                self:save_and_next(ls)
            else
                self:nextc(ls)
            end
        end--if c
    end--while
    if Token then
        local p = 3 + sep
        Token.seminfo = string.sub(ls.buff, p, -p)
    end
end

------------------------------------------------------------------------
-- reads a string
-- * has been restructured significantly compared to the original C code
-- * ccuser44 was here to add support for UTF8 string literals,
-- hex numerical string literals and the \z string literal
------------------------------------------------------------------------

function luaX:read_string(ls, del, Token)
    self:save_and_next(ls)
    while ls.current ~= del do
        local c = ls.current
        if c == "EOZ" then
            self:lexerror(ls, "unfinished string", "TK_EOS")
        elseif self:currIsNewline(ls) then
            self:lexerror(ls, "unfinished string", "TK_STRING")
        elseif c == "\\" then
            c = self:nextc(ls)  -- do not save the '\'
            if self:currIsNewline(ls) then  -- go through
                self:save(ls, "\n")
                self:inclinenumber(ls)
            elseif c ~= "EOZ" then -- will raise an error next loop
                -- escapes handling greatly simplified here:
                local i = string.find("abfnrtv", c, 1, 1)
                if i then
                    self:save(ls, string.sub("\a\b\f\n\r\t\v", i, i))
                    self:nextc(ls)
                elseif c == "u" then -- UTF8 string literal
                    assert(utf8 and utf8.char, "No utf8 library found! Cannot decode UTF8 string literal!")

                    if self:nextc(ls) ~= "{" then
                        self:lexerror("Sounds like a skill issue", "TK_STRING")
                    end

                    local unicodeCharacter = ""

                    while true do
                        c = self:nextc(ls)

                        if c == "}" then
                            break
                        elseif string.match(c, "%x") then
                            unicodeCharacter = unicodeCharacter .. c
                        else
                            self:lexerror(string.format("Invalid unicode character sequence. Expected alphanumeric character, got %s. Did you forget to close the code sequence with a curly bracket?", c), "TK_STRING")
                        end
                    end

                    if not tonumber(unicodeCharacter, 16) or not utf8.char(tonumber(unicodeCharacter, 16)) then
                        self:lexerror(string.format("Invalid UTF8 char %s. Expected a valid UTF8 character code", unicodeCharacter), "TK_STRING")
                    else
                        self:save(ls, utf8.char(tonumber(unicodeCharacter)))
                    end
                elseif string.lower(c) == "x" then -- Hex numeral literal
                    local hexNum = self:nextc(ls)..self:nextc(ls)

                    if not string.match(string.upper(hexNum), "%x") then
                        self:lexerror(string.format("Invalid hex string literal. Expected valid string literal, got %s", hexNum), "TK_STRING")
                    else
                        self:save(ls, string.char(tonumber(hexNum, 16)))
                    end
                elseif string.lower(c) == "z" then -- Support \z string literal. I'm not sure why you would want to use this
                    local c = luaX:nextc(ls)

                    if c == del then
                        break
                    else
                        self:save(ls, c)
                    end
                elseif not string.find(c, "%d") then
                    self:save_and_next(ls)  -- handles \\, \", \', and \?
                else  -- \xxx
                    c, i = 0, 0
                    repeat
                        c = 10 * c + ls.current
                        self:nextc(ls)
                        i = i + 1
                    until i >= 3 or not string.find(ls.current, "%d")
                    if c > 255 then  -- UCHAR_MAX
                        self:lexerror(ls, "escape sequence too large", "TK_STRING")
                    end
                    self:save(ls, string.char(c))
                end
            end
        else
            self:save_and_next(ls)
        end--if c
    end--while
    self:save_and_next(ls)  -- skip delimiter
    Token.seminfo = string.sub(ls.buff, 2, -2)
end

------------------------------------------------------------------------
-- main lexer function
------------------------------------------------------------------------
function luaX:llex(ls, Token)
    ls.buff = ""
    while true do
        local c = ls.current
        ----------------------------------------------------------------
        if self:currIsNewline(ls) then
            self:inclinenumber(ls)
            ----------------------------------------------------------------
        elseif c == "-" then
            c = self:nextc(ls)
            if c == "=" then self:nextc(ls); return "TK_ASSIGN_SUB" -- Luau Compound 
            elseif c ~= "-" then return "-" end
            -- else is a comment
            local sep = -1
            if self:nextc(ls) == '[' then
                sep = self:skip_sep(ls)
                ls.buff = ""  -- 'skip_sep' may dirty the buffer
            end
            if sep >= 0 then
                self:read_long_string(ls, nil, sep)  -- long comment
                ls.buff = ""
            else  -- else short comment
                while not self:currIsNewline(ls) and ls.current ~= "EOZ" do
                    self:nextc(ls)
                end
            end
            ----------------------------------------------------------------
        elseif c == "[" then
            local sep = self:skip_sep(ls)
            if sep >= 0 then
                self:read_long_string(ls, Token, sep)
                return "TK_STRING"
            elseif sep == -1 then
                return "["
            else
                self:lexerror(ls, "invalid long string delimiter", "TK_STRING")
            end
            ---------------------Luau Compound Start------------------------
        elseif c == "+" then
            c = self:nextc(ls)
            if c ~= "=" then return "+"
            else self:nextc(ls); return "TK_ASSIGN_ADD" end
            ----------------------------------------------------------------
        elseif c == "*" then
            c = self:nextc(ls)
            if c ~= "=" then return "*"
            else self:nextc(ls); return "TK_ASSIGN_MUL" end
            ----------------------------------------------------------------
        elseif c == "/" then
            c = self:nextc(ls)
            if c ~= "=" then return "/"
            else self:nextc(ls); return "TK_ASSIGN_DIV" end
            ----------------------------------------------------------------
        elseif c == "%" then
            c = self:nextc(ls)
            if c ~= "=" then return "%"
            else self:nextc(ls); return "TK_ASSIGN_MOD" end
            ----------------------------------------------------------------
        elseif c == "^" then
            c = self:nextc(ls)
            if c ~= "=" then return "^"
            else self:nextc(ls); return "TK_ASSIGN_POW" end
            ----------------------------------------------------------------
            --             TODO: TK_ASSIGN_CONCAT support                 --
            ----------------------Luau Compound End-------------------------
        elseif c == "=" then
            c = self:nextc(ls)
            if c ~= "=" then return "="
            else self:nextc(ls); return "TK_EQ" end
            ----------------------------------------------------------------
        elseif c == "<" then
            c = self:nextc(ls)
            if c ~= "=" then return "<"
            else self:nextc(ls); return "TK_LE" end
            ----------------------------------------------------------------
        elseif c == ">" then
            c = self:nextc(ls)
            if c ~= "=" then return ">"
            else self:nextc(ls); return "TK_GE" end
            ----------------------------------------------------------------
        elseif c == "~" then
            c = self:nextc(ls)
            if c ~= "=" then return "~"
            else self:nextc(ls); return "TK_NE" end
            ----------------------------------------------------------------
        elseif c == "\"" or c == "'" then
            self:read_string(ls, c, Token)
            return "TK_STRING"
            ----------------------------------------------------------------
        elseif c == "." then
            c = self:save_and_next(ls)
            if self:check_next(ls, ".") then
                if self:check_next(ls, ".") then
                    return "TK_DOTS"   -- ...
                else return "TK_CONCAT"   -- ..
                end
            elseif not string.find(c, "%d") then
                return "."
            else
                self:read_numeral(ls, Token)
                return "TK_NUMBER"
            end
            ----------------------------------------------------------------
        elseif c == "EOZ" then
            return "TK_EOS"
            ----------------------------------------------------------------
        else  -- default
            if string.find(c, "%s") then
                -- lua_assert(self:currIsNewline(ls))
                self:nextc(ls)
            elseif string.find(c, "%d") then
                self:read_numeral(ls, Token)
                return "TK_NUMBER"
            elseif string.find(c, "[_%a]") then
                -- identifier or reserved word
                repeat
                    c = self:save_and_next(ls)
                until c == "EOZ" or not string.find(c, "[_%w]")
                local ts = ls.buff
                local tok = self.enums[ts]
                if tok then return tok end  -- reserved word?
                Token.seminfo = ts
                return "TK_NAME"
            else
                self:nextc(ls)
                return c  -- single-char tokens (+ - / ...)
            end
            ----------------------------------------------------------------
        end--if c
    end--while
end

--# selene: allow(incorrect_standard_library_use, multiple_statements, shadowing, unused_variable, empty_if, divide_by_zero, unbalanced_assignments)
--[[

  lcode.lua
  Lua 5 code generator in Lua
  This file is part of Yueliang.

  Copyright (c) 2005-2007 Kein-Hong Man <khman@users.sf.net>
  The COPYRIGHT file describes the conditions
  under which this software may be distributed.

  See the ChangeLog for more information.

]]

--[[
-- Notes:
-- * one function manipulate a pointer argument with a simple data type
--   (can't be emulated by a table, ambiguous), now returns that value:
--   luaK:concat(fs, l1, l2)
-- * luaM_growvector uses the faux luaY:growvector, for limit checking
-- * some function parameters changed to boolean, additional code
--   translates boolean back to 1/0 for instruction fields
--
-- Not implemented:
-- * NOTE there is a failed assert in luaK:addk, a porting problem
--
-- Added:
-- * constant MAXSTACK from llimits.h
-- * luaK:ttisnumber(o) (from lobject.h)
-- * luaK:nvalue(o) (from lobject.h)
-- * luaK:setnilvalue(o) (from lobject.h)
-- * luaK:setnvalue(o, x) (from lobject.h)
-- * luaK:setbvalue(o, x) (from lobject.h)
-- * luaK:sethvalue(o, x) (from lobject.h), parameter L deleted
-- * luaK:setsvalue(o, x) (from lobject.h), parameter L deleted
-- * luaK:numadd, luaK:numsub, luaK:nummul, luaK:numdiv, luaK:nummod,
--   luaK:numpow, luaK:numunm, luaK:numisnan (from luaconf.h)
-- * copyexp(e1, e2) added in luaK:posfix to copy expdesc struct
--
-- Changed in 5.1.x:
-- * enum BinOpr has a new entry, OPR_MOD
-- * enum UnOpr has a new entry, OPR_LEN
-- * binopistest, unused in 5.0.x, has been deleted
-- * macro setmultret is new
-- * functions isnumeral, luaK_ret, boolK are new
-- * funcion nilK was named nil_constant in 5.0.x
-- * function interface changed: need_value, patchtestreg, concat
-- * TObject now a TValue
-- * functions luaK_setreturns, luaK_setoneret are new
-- * function luaK:setcallreturns deleted, to be replaced by:
--   luaK:setmultret, luaK:ret, luaK:setreturns, luaK:setoneret
-- * functions constfolding, codearith, codecomp are new
-- * luaK:codebinop has been deleted
-- * function luaK_setlist is new
-- * OPR_MULT renamed to OPR_MUL
]]

local luaY
local luaK = {}

------------------------------------------------------------------------
-- constants used by code generator
------------------------------------------------------------------------
-- maximum stack for a Lua function
luaK.MAXSTACK = 250  -- (from llimits.h)

--[[
-- other functions
]]

------------------------------------------------------------------------
-- emulation of TValue macros (these are from lobject.h)
-- * TValue is a table since lcode passes references around
-- * tt member field removed, using Lua's type() instead
-- * for setsvalue, sethvalue, parameter L (deleted here) in lobject.h
--   is used in an assert for testing, see checkliveness(g,obj)
------------------------------------------------------------------------
function luaK:ttisnumber(o)
    if o then return type(o.value) == "number" else return false end
end
function luaK:nvalue(o) return o.value end
function luaK:setnilvalue(o) o.value = nil end
function luaK:setsvalue(o, x) o.value = x end
luaK.setnvalue = luaK.setsvalue
luaK.sethvalue = luaK.setsvalue
luaK.setbvalue = luaK.setsvalue

------------------------------------------------------------------------
-- The luai_num* macros define the primitive operations over numbers.
-- * this is not the entire set of primitive operations from luaconf.h
-- * used in luaK:constfolding()
------------------------------------------------------------------------
function luaK:numadd(a, b) return a + b end
function luaK:numsub(a, b) return a - b end
function luaK:nummul(a, b) return a * b end
function luaK:numdiv(a, b) return a / b end
function luaK:nummod(a, b) return a % b end
-- ((a) - floor((a)/(b))*(b)) /* actual, for reference */
function luaK:numpow(a, b) return a ^ b end
function luaK:numunm(a) return -a end
function luaK:numisnan(a) return not a == a end
-- a NaN cannot equal another NaN

--[[
-- code generator functions
]]

------------------------------------------------------------------------
-- Marks the end of a patch list. It is an invalid value both as an absolute
-- address, and as a list link (would link an element to itself).
------------------------------------------------------------------------
luaK.NO_JUMP = -1

------------------------------------------------------------------------
-- grep "ORDER OPR" if you change these enums
------------------------------------------------------------------------
luaK.BinOpr = {
    OPR_ADD = 0, OPR_SUB = 1, OPR_MUL = 2, OPR_DIV = 3, OPR_MOD = 4, OPR_POW = 5,
    OPR_CONCAT = 6,
    OPR_NE = 7, OPR_EQ = 8,
    OPR_LT = 9, OPR_LE = 10, OPR_GT = 11, OPR_GE = 12,
    OPR_AND = 13, OPR_OR = 14,
    OPR_NOBINOPR = 15,
}

-- * UnOpr is used by luaK:prefix's op argument, but not directly used
--   because the function receives the symbols as strings, e.g. "OPR_NOT"
luaK.UnOpr = {
    OPR_MINUS = 0, OPR_NOT = 1, OPR_LEN = 2, OPR_NOUNOPR = 3
}

------------------------------------------------------------------------
-- returns the instruction object for given e (expdesc), was a macro
------------------------------------------------------------------------
function luaK:getcode(fs, e)
    return fs.f.code[e.info]
end

------------------------------------------------------------------------
-- codes an instruction with a signed Bx (sBx) field, was a macro
-- * used in luaK:jump(), (lparser) luaY:forbody()
------------------------------------------------------------------------
function luaK:codeAsBx(fs, o, A, sBx)
    return self:codeABx(fs, o, A, sBx + luaP.MAXARG_sBx)
end

------------------------------------------------------------------------
-- set the expdesc e instruction for multiple returns, was a macro
------------------------------------------------------------------------
function luaK:setmultret(fs, e)
    self:setreturns(fs, e, luaY.LUA_MULTRET)
end

------------------------------------------------------------------------
-- there is a jump if patch lists are not identical, was a macro
-- * used in luaK:exp2reg(), luaK:exp2anyreg(), luaK:exp2val()
------------------------------------------------------------------------
function luaK:hasjumps(e)
    return e.t ~= e.f
end

------------------------------------------------------------------------
-- true if the expression is a constant number (for constant folding)
-- * used in constfolding(), infix()
------------------------------------------------------------------------
function luaK:isnumeral(e)
    return e.k == "VKNUM" and e.t == self.NO_JUMP and e.f == self.NO_JUMP
end

------------------------------------------------------------------------
-- codes loading of nil, optimization done if consecutive locations
-- * used in luaK:discharge2reg(), (lparser) luaY:adjust_assign()
------------------------------------------------------------------------
function luaK:_nil(fs, from, n)
    if fs.pc > fs.lasttarget then  -- no jumps to current position?
        if fs.pc == 0 then  -- function start?
            if from >= fs.nactvar then
                return  -- positions are already clean
            end
        else
            local previous = fs.f.code[fs.pc - 1]
            if luaP:GET_OPCODE(previous) == "OP_LOADNIL" then
                local pfrom = luaP:GETARG_A(previous)
                local pto = luaP:GETARG_B(previous)
                if pfrom <= from and from <= pto + 1 then  -- can connect both?
                    if from + n - 1 > pto then
                        luaP:SETARG_B(previous, from + n - 1)
                    end
                    return
                end
            end
        end
    end
    self:codeABC(fs, "OP_LOADNIL", from, from + n - 1, 0)  -- else no optimization
end

------------------------------------------------------------------------
--
-- * used in multiple locations
------------------------------------------------------------------------
function luaK:jump(fs)
    local jpc = fs.jpc  -- save list of jumps to here
    fs.jpc = self.NO_JUMP
    local j = self:codeAsBx(fs, "OP_JMP", 0, self.NO_JUMP)
    j = self:concat(fs, j, jpc)  -- keep them on hold
    return j
end

------------------------------------------------------------------------
-- codes a RETURN instruction
-- * used in luaY:close_func(), luaY:retstat()
------------------------------------------------------------------------
function luaK:ret(fs, first, nret)
    self:codeABC(fs, "OP_RETURN", first, nret + 1, 0)
end

------------------------------------------------------------------------
--
-- * used in luaK:jumponcond(), luaK:codecomp()
------------------------------------------------------------------------
function luaK:condjump(fs, op, A, B, C)
    self:codeABC(fs, op, A, B, C)
    return self:jump(fs)
end

------------------------------------------------------------------------
--
-- * used in luaK:patchlistaux(), luaK:concat()
------------------------------------------------------------------------
function luaK:fixjump(fs, pc, dest)
    local jmp = fs.f.code[pc]
    local offset = dest - (pc + 1)
    assert(dest ~= self.NO_JUMP)
    if math.abs(offset) > luaP.MAXARG_sBx then
        luaX:syntaxerror(fs.ls, "control structure too long")
    end
    luaP:SETARG_sBx(jmp, offset)
end

------------------------------------------------------------------------
-- returns current 'pc' and marks it as a jump target (to avoid wrong
-- optimizations with consecutive instructions not in the same basic block).
-- * used in multiple locations
-- * fs.lasttarget tested only by luaK:_nil() when optimizing OP_LOADNIL
------------------------------------------------------------------------
function luaK:getlabel(fs)
    fs.lasttarget = fs.pc
    return fs.pc
end

------------------------------------------------------------------------
--
-- * used in luaK:need_value(), luaK:removevalues(), luaK:patchlistaux(),
--   luaK:concat()
------------------------------------------------------------------------
function luaK:getjump(fs, pc)
    local offset = luaP:GETARG_sBx(fs.f.code[pc])
    if offset == self.NO_JUMP then  -- point to itself represents end of list
        return self.NO_JUMP  -- end of list
    else
        return (pc + 1) + offset  -- turn offset into absolute position
    end
end

------------------------------------------------------------------------
--
-- * used in luaK:need_value(), luaK:patchtestreg(), luaK:invertjump()
------------------------------------------------------------------------
function luaK:getjumpcontrol(fs, pc)
    local pi = fs.f.code[pc]
    local ppi = fs.f.code[pc - 1]
    if pc >= 1 and luaP:testTMode(luaP:GET_OPCODE(ppi)) ~= 0 then
        return ppi
    else
        return pi
    end
end

------------------------------------------------------------------------
-- check whether list has any jump that do not produce a value
-- (or produce an inverted value)
-- * return value changed to boolean
-- * used only in luaK:exp2reg()
------------------------------------------------------------------------
function luaK:need_value(fs, list)
    while list ~= self.NO_JUMP do
        local i = self:getjumpcontrol(fs, list)
        if luaP:GET_OPCODE(i) ~= "OP_TESTSET" then return true end
        list = self:getjump(fs, list)
    end
    return false  -- not found
end

------------------------------------------------------------------------
--
-- * used in luaK:removevalues(), luaK:patchlistaux()
------------------------------------------------------------------------
function luaK:patchtestreg(fs, node, reg)
    local i = self:getjumpcontrol(fs, node)
    if luaP:GET_OPCODE(i) ~= "OP_TESTSET" then
        return false  -- cannot patch other instructions
    end
    if reg ~= luaP.NO_REG and reg ~= luaP:GETARG_B(i) then
        luaP:SETARG_A(i, reg)
    else  -- no register to put value or register already has the value
        -- due to use of a table as i, i cannot be replaced by another table
        -- so the following is required; there is no change to ARG_C
        luaP:SET_OPCODE(i, "OP_TEST")
        local b = luaP:GETARG_B(i)
        luaP:SETARG_A(i, b)
        luaP:SETARG_B(i, 0)
        -- *i = CREATE_ABC(OP_TEST, GETARG_B(*i), 0, GETARG_C(*i)); /* C */
    end
    return true
end

------------------------------------------------------------------------
--
-- * used only in luaK:codenot()
------------------------------------------------------------------------
function luaK:removevalues(fs, list)
    while list ~= self.NO_JUMP do
        self:patchtestreg(fs, list, luaP.NO_REG)
        list = self:getjump(fs, list)
    end
end

------------------------------------------------------------------------
--
-- * used in luaK:dischargejpc(), luaK:patchlist(), luaK:exp2reg()
------------------------------------------------------------------------
function luaK:patchlistaux(fs, list, vtarget, reg, dtarget)
    while list ~= self.NO_JUMP do
        local _next = self:getjump(fs, list)
        if self:patchtestreg(fs, list, reg) then
            self:fixjump(fs, list, vtarget)
        else
            self:fixjump(fs, list, dtarget)  -- jump to default target
        end
        list = _next
    end
end

------------------------------------------------------------------------
--
-- * used only in luaK:code()
------------------------------------------------------------------------
function luaK:dischargejpc(fs)
    self:patchlistaux(fs, fs.jpc, fs.pc, luaP.NO_REG, fs.pc)
    fs.jpc = self.NO_JUMP
end

------------------------------------------------------------------------
--
-- * used in (lparser) luaY:whilestat(), luaY:repeatstat(), luaY:forbody()
------------------------------------------------------------------------
function luaK:patchlist(fs, list, target)
    if target == fs.pc then
        self:patchtohere(fs, list)
    else
        assert(target < fs.pc)
        self:patchlistaux(fs, list, target, luaP.NO_REG, target)
    end
end

------------------------------------------------------------------------
--
-- * used in multiple locations
------------------------------------------------------------------------
function luaK:patchtohere(fs, list)
    self:getlabel(fs)
    fs.jpc = self:concat(fs, fs.jpc, list)
end

------------------------------------------------------------------------
-- * l1 was a pointer, now l1 is returned and callee assigns the value
-- * used in multiple locations
------------------------------------------------------------------------
function luaK:concat(fs, l1, l2)
    if l2 == self.NO_JUMP then return l1
    elseif l1 == self.NO_JUMP then
        return l2
    else
        local list = l1
        local _next = self:getjump(fs, list)
        while _next ~= self.NO_JUMP do  -- find last element
            list = _next
            _next = self:getjump(fs, list)
        end
        self:fixjump(fs, list, l2)
    end
    return l1
end

------------------------------------------------------------------------
--
-- * used in luaK:reserveregs(), (lparser) luaY:forlist()
------------------------------------------------------------------------
function luaK:checkstack(fs, n)
    local newstack = fs.freereg + n
    if newstack > fs.f.maxstacksize then
        if newstack >= self.MAXSTACK then
            luaX:syntaxerror(fs.ls, "function or expression too complex")
        end
        fs.f.maxstacksize = newstack
    end
end

------------------------------------------------------------------------
--
-- * used in multiple locations
------------------------------------------------------------------------
function luaK:reserveregs(fs, n)
    self:checkstack(fs, n)
    fs.freereg = fs.freereg + n
end

------------------------------------------------------------------------
--
-- * used in luaK:freeexp(), luaK:dischargevars()
------------------------------------------------------------------------
function luaK:freereg(fs, reg)
    if not luaP:ISK(reg) and reg >= fs.nactvar then
        fs.freereg = fs.freereg - 1
        assert(reg == fs.freereg)
    end
end

------------------------------------------------------------------------
--
-- * used in multiple locations
------------------------------------------------------------------------
function luaK:freeexp(fs, e)
    if e.k == "VNONRELOC" then
        self:freereg(fs, e.info)
    end
end

------------------------------------------------------------------------
-- * TODO NOTE implementation is not 100% correct, since the assert fails
-- * luaH_set, setobj deleted; direct table access used instead
-- * used in luaK:stringK(), luaK:numberK(), luaK:boolK(), luaK:nilK()
------------------------------------------------------------------------
function luaK:addk(fs, k, v)
    local L = fs.L
    local idx = fs.h[k.value]
    --TValue *idx = luaH_set(L, fs->h, k); /* C */
    local f = fs.f
    if self:ttisnumber(idx) then
        --TODO this assert currently FAILS (last tested for 5.0.2)
        --assert(fs.f.k[self:nvalue(idx)] == v)
        --assert(luaO_rawequalObj(&fs->f->k[cast_int(nvalue(idx))], v)); /* C */
        return self:nvalue(idx)
    else -- constant not found; create a new entry
        idx = {}
        self:setnvalue(idx, fs.nk)
        fs.h[k.value] = idx
        -- setnvalue(idx, cast_num(fs->nk)); /* C */
        luaY:growvector(L, f.k, fs.nk, f.sizek, nil,
            luaP.MAXARG_Bx, "constant table overflow")
        -- loop to initialize empty f.k positions not required
        f.k[fs.nk] = v
        -- setobj(L, &f->k[fs->nk], v); /* C */
        -- luaC_barrier(L, f, v); /* GC */
        local nk = fs.nk
        fs.nk = fs.nk + 1
        return nk
    end

end

------------------------------------------------------------------------
-- creates and sets a string object
-- * used in (lparser) luaY:codestring(), luaY:singlevar()
------------------------------------------------------------------------
function luaK:stringK(fs, s)
    local o = {}  -- TValue
    self:setsvalue(o, s)
    return self:addk(fs, o, o)
end

------------------------------------------------------------------------
-- creates and sets a number object
-- * used in luaK:prefix() for negative (or negation of) numbers
-- * used in (lparser) luaY:simpleexp(), luaY:fornum()
------------------------------------------------------------------------
function luaK:numberK(fs, r)
    local o = {}  -- TValue
    self:setnvalue(o, r)
    return self:addk(fs, o, o)
end

------------------------------------------------------------------------
-- creates and sets a boolean object
-- * used only in luaK:exp2RK()
------------------------------------------------------------------------
function luaK:boolK(fs, b)
    local o = {}  -- TValue
    self:setbvalue(o, b)
    return self:addk(fs, o, o)
end

------------------------------------------------------------------------
-- creates and sets a nil object
-- * used only in luaK:exp2RK()
------------------------------------------------------------------------
function luaK:nilK(fs)
    local k, v = {}, {}  -- TValue
    self:setnilvalue(v)
    -- cannot use nil as key; instead use table itself to represent nil
    self:sethvalue(k, fs.h)
    return self:addk(fs, k, v)
end

------------------------------------------------------------------------
--
-- * used in luaK:setmultret(), (lparser) luaY:adjust_assign()
------------------------------------------------------------------------
function luaK:setreturns(fs, e, nresults)
    if e.k == "VCALL" then  -- expression is an open function call?
        luaP:SETARG_C(self:getcode(fs, e), nresults + 1)
    elseif e.k == "VVARARG" then
        luaP:SETARG_B(self:getcode(fs, e), nresults + 1);
        luaP:SETARG_A(self:getcode(fs, e), fs.freereg);
        luaK:reserveregs(fs, 1)
    end
end

------------------------------------------------------------------------
--
-- * used in luaK:dischargevars(), (lparser) luaY:assignment()
------------------------------------------------------------------------
function luaK:setoneret(fs, e)
    if e.k == "VCALL" then  -- expression is an open function call?
        e.k = "VNONRELOC"
        e.info = luaP:GETARG_A(self:getcode(fs, e))
    elseif e.k == "VVARARG" then
        luaP:SETARG_B(self:getcode(fs, e), 2)
        e.k = "VRELOCABLE"  -- can relocate its simple result
    end
end

------------------------------------------------------------------------
--
-- * used in multiple locations
------------------------------------------------------------------------
function luaK:dischargevars(fs, e)
    local k = e.k
    if k == "VLOCAL" then
        e.k = "VNONRELOC"
    elseif k == "VUPVAL" then
        e.info = self:codeABC(fs, "OP_GETUPVAL", 0, e.info, 0)
        e.k = "VRELOCABLE"
    elseif k == "VGLOBAL" then
        e.info = self:codeABx(fs, "OP_GETGLOBAL", 0, e.info)
        e.k = "VRELOCABLE"
    elseif k == "VINDEXED" then
        self:freereg(fs, e.aux)
        self:freereg(fs, e.info)
        e.info = self:codeABC(fs, "OP_GETTABLE", 0, e.info, e.aux)
        e.k = "VRELOCABLE"
    elseif k == "VVARARG" or k == "VCALL" then
        self:setoneret(fs, e)
    else
        -- there is one value available (somewhere)
    end
end

------------------------------------------------------------------------
--
-- * used only in luaK:exp2reg()
------------------------------------------------------------------------
function luaK:code_label(fs, A, b, jump)
    self:getlabel(fs)  -- those instructions may be jump targets
    return self:codeABC(fs, "OP_LOADBOOL", A, b, jump)
end

------------------------------------------------------------------------
--
-- * used in luaK:discharge2anyreg(), luaK:exp2reg()
------------------------------------------------------------------------
function luaK:discharge2reg(fs, e, reg)
    self:dischargevars(fs, e)
    local k = e.k
    if k == "VNIL" then
        self:_nil(fs, reg, 1)
    elseif k == "VFALSE" or k == "VTRUE" then
        self:codeABC(fs, "OP_LOADBOOL", reg, (e.k == "VTRUE") and 1 or 0, 0)
    elseif k == "VK" then
        self:codeABx(fs, "OP_LOADK", reg, e.info)
    elseif k == "VKNUM" then
        self:codeABx(fs, "OP_LOADK", reg, self:numberK(fs, e.nval))
    elseif k == "VRELOCABLE" then
        local pc = self:getcode(fs, e)
        luaP:SETARG_A(pc, reg)
    elseif k == "VNONRELOC" then
        if reg ~= e.info then
            self:codeABC(fs, "OP_MOVE", reg, e.info, 0)
        end
    else
        assert(e.k == "VVOID" or e.k == "VJMP")
        return  -- nothing to do...
    end
    e.info = reg
    e.k = "VNONRELOC"
end

------------------------------------------------------------------------
--
-- * used in luaK:jumponcond(), luaK:codenot()
------------------------------------------------------------------------
function luaK:discharge2anyreg(fs, e)
    if e.k ~= "VNONRELOC" then
        self:reserveregs(fs, 1)
        self:discharge2reg(fs, e, fs.freereg - 1)
    end
end

------------------------------------------------------------------------
--
-- * used in luaK:exp2nextreg(), luaK:exp2anyreg(), luaK:storevar()
------------------------------------------------------------------------
function luaK:exp2reg(fs, e, reg)
    self:discharge2reg(fs, e, reg)
    if e.k == "VJMP" then
        e.t = self:concat(fs, e.t, e.info)  -- put this jump in 't' list
    end
    if self:hasjumps(e) then
        local final  -- position after whole expression
        local p_f = self.NO_JUMP  -- position of an eventual LOAD false
        local p_t = self.NO_JUMP  -- position of an eventual LOAD true
        if self:need_value(fs, e.t) or self:need_value(fs, e.f) then
            local fj = (e.k == "VJMP") and self.NO_JUMP or self:jump(fs)
            p_f = self:code_label(fs, reg, 0, 1)
            p_t = self:code_label(fs, reg, 1, 0)
            self:patchtohere(fs, fj)
        end
        final = self:getlabel(fs)
        self:patchlistaux(fs, e.f, final, reg, p_f)
        self:patchlistaux(fs, e.t, final, reg, p_t)
    end
    e.f, e.t = self.NO_JUMP, self.NO_JUMP
    e.info = reg
    e.k = "VNONRELOC"
end

------------------------------------------------------------------------
--
-- * used in multiple locations
------------------------------------------------------------------------
function luaK:exp2nextreg(fs, e)
    self:dischargevars(fs, e)
    self:freeexp(fs, e)
    self:reserveregs(fs, 1)
    self:exp2reg(fs, e, fs.freereg - 1)
end

------------------------------------------------------------------------
--
-- * used in multiple locations
------------------------------------------------------------------------
function luaK:exp2anyreg(fs, e)
    self:dischargevars(fs, e)
    if e.k == "VNONRELOC" then
        if not self:hasjumps(e) then  -- exp is already in a register
            return e.info
        end
        if e.info >= fs.nactvar then  -- reg. is not a local?
            self:exp2reg(fs, e, e.info)  -- put value on it
            return e.info
        end
    end
    self:exp2nextreg(fs, e)  -- default
    return e.info
end

------------------------------------------------------------------------
--
-- * used in luaK:exp2RK(), luaK:prefix(), luaK:posfix()
-- * used in (lparser) luaY:yindex()
------------------------------------------------------------------------
function luaK:exp2val(fs, e)
    if self:hasjumps(e) then
        self:exp2anyreg(fs, e)
    else
        self:dischargevars(fs, e)
    end
end

------------------------------------------------------------------------
--
-- * used in multiple locations
------------------------------------------------------------------------
function luaK:exp2RK(fs, e)
    self:exp2val(fs, e)
    local k = e.k
    if k == "VKNUM" or k == "VTRUE" or k == "VFALSE" or k == "VNIL" then
        if fs.nk <= luaP.MAXINDEXRK then  -- constant fit in RK operand?
            -- converted from a 2-deep ternary operator expression
            if e.k == "VNIL" then
                e.info = self:nilK(fs)
            else
                e.info = (e.k == "VKNUM") and self:numberK(fs, e.nval)
                    or self:boolK(fs, e.k == "VTRUE")
            end
            e.k = "VK"
            return luaP:RKASK(e.info)
        end
    elseif k == "VK" then
        if e.info <= luaP.MAXINDEXRK then  -- constant fit in argC?
            return luaP:RKASK(e.info)
        end
    else
        -- default
    end
    -- not a constant in the right range: put it in a register
    return self:exp2anyreg(fs, e)
end

------------------------------------------------------------------------
--
-- * used in (lparser) luaY:assignment(), luaY:localfunc(), luaY:funcstat()
------------------------------------------------------------------------
function luaK:storevar(fs, var, ex)
    local k = var.k
    if k == "VLOCAL" then
        self:freeexp(fs, ex)
        self:exp2reg(fs, ex, var.info)
        return
    elseif k == "VUPVAL" then
        local e = self:exp2anyreg(fs, ex)
        self:codeABC(fs, "OP_SETUPVAL", e, var.info, 0)
    elseif k == "VGLOBAL" then
        local e = self:exp2anyreg(fs, ex)
        self:codeABx(fs, "OP_SETGLOBAL", e, var.info)
    elseif k == "VINDEXED" then
        local e = self:exp2RK(fs, ex)
        self:codeABC(fs, "OP_SETTABLE", var.info, var.aux, e)
    else
        assert(0)  -- invalid var kind to store
    end
    self:freeexp(fs, ex)
end

------------------------------------------------------------------------
--
-- * used only in (lparser) luaY:primaryexp()
------------------------------------------------------------------------
function luaK:_self(fs, e, key)
    self:exp2anyreg(fs, e)
    self:freeexp(fs, e)
    local func = fs.freereg
    self:reserveregs(fs, 2)
    self:codeABC(fs, "OP_SELF", func, e.info, self:exp2RK(fs, key))
    self:freeexp(fs, key)
    e.info = func
    e.k = "VNONRELOC"
end

------------------------------------------------------------------------
--
-- * used in luaK:goiftrue(), luaK:codenot()
------------------------------------------------------------------------
function luaK:invertjump(fs, e)
    local pc = self:getjumpcontrol(fs, e.info)
    assert(luaP:testTMode(luaP:GET_OPCODE(pc)) ~= 0 and
        luaP:GET_OPCODE(pc) ~= "OP_TESTSET" and
        luaP:GET_OPCODE(pc) ~= "OP_TEST")
    luaP:SETARG_A(pc, (luaP:GETARG_A(pc) == 0) and 1 or 0)
end

------------------------------------------------------------------------
--
-- * used in luaK:goiftrue(), luaK:goiffalse()
------------------------------------------------------------------------
function luaK:jumponcond(fs, e, cond)
    if e.k == "VRELOCABLE" then
        local ie = self:getcode(fs, e)
        if luaP:GET_OPCODE(ie) == "OP_NOT" then
            fs.pc = fs.pc - 1  -- remove previous OP_NOT
            return self:condjump(fs, "OP_TEST", luaP:GETARG_B(ie), 0, cond and 0 or 1)
        end
        -- else go through
    end
    self:discharge2anyreg(fs, e)
    self:freeexp(fs, e)
    return self:condjump(fs, "OP_TESTSET", luaP.NO_REG, e.info, cond and 1 or 0)
end

------------------------------------------------------------------------
--
-- * used in luaK:infix(), (lparser) luaY:cond()
------------------------------------------------------------------------
function luaK:goiftrue(fs, e)
    local pc  -- pc of last jump
    self:dischargevars(fs, e)
    local k = e.k
    if k == "VK" or k == "VKNUM" or k == "VTRUE" then
        pc = self.NO_JUMP  -- always true; do nothing
    elseif k == "VFALSE" then
        pc = self:jump(fs)  -- always jump
    elseif k == "VJMP" then
        self:invertjump(fs, e)
        pc = e.info
    else
        pc = self:jumponcond(fs, e, false)
    end
    e.f = self:concat(fs, e.f, pc)  -- insert last jump in `f' list
    self:patchtohere(fs, e.t)
    e.t = self.NO_JUMP
end

------------------------------------------------------------------------
--
-- * used in luaK:infix()
------------------------------------------------------------------------
function luaK:goiffalse(fs, e)
    local pc  -- pc of last jump
    self:dischargevars(fs, e)
    local k = e.k
    if k == "VNIL" or k == "VFALSE"then
        pc = self.NO_JUMP  -- always false; do nothing
    elseif k == "VTRUE" then
        pc = self:jump(fs)  -- always jump
    elseif k == "VJMP" then
        pc = e.info
    else
        pc = self:jumponcond(fs, e, true)
    end
    e.t = self:concat(fs, e.t, pc)  -- insert last jump in `t' list
    self:patchtohere(fs, e.f)
    e.f = self.NO_JUMP
end

------------------------------------------------------------------------
--
-- * used only in luaK:prefix()
------------------------------------------------------------------------
function luaK:codenot(fs, e)
    self:dischargevars(fs, e)
    local k = e.k
    if k == "VNIL" or k == "VFALSE" then
        e.k = "VTRUE"
    elseif k == "VK" or k == "VKNUM" or k == "VTRUE" then
        e.k = "VFALSE"
    elseif k == "VJMP" then
        self:invertjump(fs, e)
    elseif k == "VRELOCABLE" or k == "VNONRELOC" then
        self:discharge2anyreg(fs, e)
        self:freeexp(fs, e)
        e.info = self:codeABC(fs, "OP_NOT", 0, e.info, 0)
        e.k = "VRELOCABLE"
    else
        assert(0)  -- cannot happen
    end
    -- interchange true and false lists
    e.f, e.t = e.t, e.f
    self:removevalues(fs, e.f)
    self:removevalues(fs, e.t)
end

------------------------------------------------------------------------
--
-- * used in (lparser) luaY:field(), luaY:primaryexp()
------------------------------------------------------------------------
function luaK:indexed(fs, t, k)
    t.aux = self:exp2RK(fs, k)
    t.k = "VINDEXED"
end

------------------------------------------------------------------------
--
-- * used only in luaK:codearith()
------------------------------------------------------------------------
function luaK:constfolding(op, e1, e2)
    local r
    if not self:isnumeral(e1) or not self:isnumeral(e2) then return false end
    local v1 = e1.nval
    local v2 = e2.nval
    if op == "OP_ADD" then
        r = self:numadd(v1, v2)
    elseif op == "OP_SUB" then
        r = self:numsub(v1, v2)
    elseif op == "OP_MUL" then
        r = self:nummul(v1, v2)
    elseif op == "OP_DIV" then
        if v2 == 0 then return false end  -- do not attempt to divide by 0
        r = self:numdiv(v1, v2)
    elseif op == "OP_MOD" then
        if v2 == 0 then return false end  -- do not attempt to divide by 0
        r = self:nummod(v1, v2)
    elseif op == "OP_POW" then
        r = self:numpow(v1, v2)
    elseif op == "OP_UNM" then
        r = self:numunm(v1)
    elseif op == "OP_LEN" then
        return false  -- no constant folding for 'len'
    else
        assert(0)
        r = 0
    end
    if self:numisnan(r) then return false end  -- do not attempt to produce NaN
    e1.nval = r
    return true
end

------------------------------------------------------------------------
--
-- * used in luaK:prefix(), luaK:posfix()
------------------------------------------------------------------------
function luaK:codearith(fs, op, e1, e2)
    if self:constfolding(op, e1, e2) then
        return
    else
        local o2 = (op ~= "OP_UNM" and op ~= "OP_LEN") and self:exp2RK(fs, e2) or 0
        local o1 = self:exp2RK(fs, e1)
        if o1 > o2 then
            self:freeexp(fs, e1)
            self:freeexp(fs, e2)
        else
            self:freeexp(fs, e2)
            self:freeexp(fs, e1)
        end
        e1.info = self:codeABC(fs, op, 0, o1, o2)
        e1.k = "VRELOCABLE"
    end
end

------------------------------------------------------------------------
--
-- * used only in luaK:posfix()
------------------------------------------------------------------------
function luaK:codecomp(fs, op, cond, e1, e2)
    local o1 = self:exp2RK(fs, e1)
    local o2 = self:exp2RK(fs, e2)
    self:freeexp(fs, e2)
    self:freeexp(fs, e1)
    if cond == 0 and op ~= "OP_EQ" then
        -- exchange args to replace by `<' or `<='
        o1, o2 = o2, o1  -- o1 <==> o2
        cond = 1
    end
    e1.info = self:condjump(fs, op, cond, o1, o2)
    e1.k = "VJMP"
end

------------------------------------------------------------------------
--
-- * used only in (lparser) luaY:subexpr()
------------------------------------------------------------------------
function luaK:prefix(fs, op, e)
    local e2 = {}  -- expdesc
    e2.t, e2.f = self.NO_JUMP, self.NO_JUMP
    e2.k = "VKNUM"
    e2.nval = 0
    if op == "OPR_MINUS" then
        if not self:isnumeral(e) then
            self:exp2anyreg(fs, e)  -- cannot operate on non-numeric constants
        end
        self:codearith(fs, "OP_UNM", e, e2)
    elseif op == "OPR_NOT" then
        self:codenot(fs, e)
    elseif op == "OPR_LEN" then
        self:exp2anyreg(fs, e)  -- cannot operate on constants
        self:codearith(fs, "OP_LEN", e, e2)
    else
        assert(0)
    end
end

------------------------------------------------------------------------
--
-- * used only in (lparser) luaY:subexpr()
------------------------------------------------------------------------
function luaK:infix(fs, op, v)
    if op == "OPR_AND" then
        self:goiftrue(fs, v)
    elseif op == "OPR_OR" then
        self:goiffalse(fs, v)
    elseif op == "OPR_CONCAT" then
        self:exp2nextreg(fs, v)  -- operand must be on the 'stack'
    elseif op == "OPR_ADD" or op == "OPR_SUB" or
        op == "OPR_MUL" or op == "OPR_DIV" or
        op == "OPR_MOD" or op == "OPR_POW" then
        if not self:isnumeral(v) then self:exp2RK(fs, v) end
    else
        self:exp2RK(fs, v)
    end
end

------------------------------------------------------------------------
--
-- * used only in (lparser) luaY:subexpr()
------------------------------------------------------------------------
-- table lookups to simplify testing
luaK.arith_op = {
    OPR_ADD = "OP_ADD", OPR_SUB = "OP_SUB", OPR_MUL = "OP_MUL",
    OPR_DIV = "OP_DIV", OPR_MOD = "OP_MOD", OPR_POW = "OP_POW",
}
luaK.comp_op = {
    OPR_EQ = "OP_EQ", OPR_NE = "OP_EQ", OPR_LT = "OP_LT",
    OPR_LE = "OP_LE", OPR_GT = "OP_LT", OPR_GE = "OP_LE",
}
luaK.comp_cond = {
    OPR_EQ = 1, OPR_NE = 0, OPR_LT = 1,
    OPR_LE = 1, OPR_GT = 0, OPR_GE = 0,
}
function luaK:posfix(fs, op, e1, e2)
    -- needed because e1 = e2 doesn't copy values...
    -- * in 5.0.x, only k/info/aux/t/f copied, t for AND, f for OR
    --   but here, all elements are copied for completeness' sake
    local function copyexp(e1, e2)
        e1.k = e2.k
        e1.info = e2.info; e1.aux = e2.aux
        e1.nval = e2.nval
        e1.t = e2.t; e1.f = e2.f
    end
    if op == "OPR_AND" then
        assert(e1.t == self.NO_JUMP)  -- list must be closed
        self:dischargevars(fs, e2)
        e2.f = self:concat(fs, e2.f, e1.f)
        copyexp(e1, e2)
    elseif op == "OPR_OR" then
        assert(e1.f == self.NO_JUMP)  -- list must be closed
        self:dischargevars(fs, e2)
        e2.t = self:concat(fs, e2.t, e1.t)
        copyexp(e1, e2)
    elseif op == "OPR_CONCAT" then
        self:exp2val(fs, e2)
        if e2.k == "VRELOCABLE" and luaP:GET_OPCODE(self:getcode(fs, e2)) == "OP_CONCAT" then
            assert(e1.info == luaP:GETARG_B(self:getcode(fs, e2)) - 1)
            self:freeexp(fs, e1)
            luaP:SETARG_B(self:getcode(fs, e2), e1.info)
            e1.k = "VRELOCABLE"
            e1.info = e2.info
        else
            self:exp2nextreg(fs, e2)  -- operand must be on the 'stack'
            self:codearith(fs, "OP_CONCAT", e1, e2)
        end
    else
        -- the following uses a table lookup in place of conditionals
        local arith = self.arith_op[op]
        if arith then
            self:codearith(fs, arith, e1, e2)
        else
            local comp = self.comp_op[op]
            if comp then
                self:codecomp(fs, comp, self.comp_cond[op], e1, e2)
            else
                assert(0)
            end
        end--if arith
    end--if op
end

------------------------------------------------------------------------
-- adjusts debug information for last instruction written, in order to
-- change the line where item comes into existence
-- * used in (lparser) luaY:funcargs(), luaY:forbody(), luaY:funcstat()
------------------------------------------------------------------------
function luaK:fixline(fs, line)
    fs.f.lineinfo[fs.pc - 1] = line
end

------------------------------------------------------------------------
-- general function to write an instruction into the instruction buffer,
-- sets debug information too
-- * used in luaK:codeABC(), luaK:codeABx()
-- * called directly by (lparser) luaY:whilestat()
------------------------------------------------------------------------
function luaK:code(fs, i, line)
    local f = fs.f
    self:dischargejpc(fs)  -- 'pc' will change
    -- put new instruction in code array
    luaY:growvector(fs.L, f.code, fs.pc, f.sizecode, nil,
        luaY.MAX_INT, "code size overflow")
    f.code[fs.pc] = i
    -- save corresponding line information
    luaY:growvector(fs.L, f.lineinfo, fs.pc, f.sizelineinfo, nil,
        luaY.MAX_INT, "code size overflow")
    f.lineinfo[fs.pc] = line
    local pc = fs.pc
    fs.pc = fs.pc + 1
    return pc
end

------------------------------------------------------------------------
-- writes an instruction of type ABC
-- * calls luaK:code()
------------------------------------------------------------------------
function luaK:codeABC(fs, o, a, b, c)
    assert(luaP:getOpMode(o) == luaP.OpMode.iABC)
    assert(luaP:getBMode(o) ~= luaP.OpArgMask.OpArgN or b == 0)
    assert(luaP:getCMode(o) ~= luaP.OpArgMask.OpArgN or c == 0)
    return self:code(fs, luaP:CREATE_ABC(o, a, b, c), fs.ls.lastline)
end

------------------------------------------------------------------------
-- writes an instruction of type ABx
-- * calls luaK:code(), called by luaK:codeAsBx()
------------------------------------------------------------------------
function luaK:codeABx(fs, o, a, bc)
    assert(luaP:getOpMode(o) == luaP.OpMode.iABx or
        luaP:getOpMode(o) == luaP.OpMode.iAsBx)
    assert(luaP:getCMode(o) == luaP.OpArgMask.OpArgN)
    return self:code(fs, luaP:CREATE_ABx(o, a, bc), fs.ls.lastline)
end

------------------------------------------------------------------------
--
-- * used in (lparser) luaY:closelistfield(), luaY:lastlistfield()
------------------------------------------------------------------------
function luaK:setlist(fs, base, nelems, tostore)
    local c = math.floor((nelems - 1)/luaP.LFIELDS_PER_FLUSH) + 1
    local b = (tostore == luaY.LUA_MULTRET) and 0 or tostore
    assert(tostore ~= 0)
    if c <= luaP.MAXARG_C then
        self:codeABC(fs, "OP_SETLIST", base, b, c)
    else
        self:codeABC(fs, "OP_SETLIST", base, b, 0)
        self:code(fs, luaP:CREATE_Inst(c), fs.ls.lastline)
    end
    fs.freereg = base + 1  -- free registers with list values
end

--# selene: allow(incorrect_standard_library_use, multiple_statements, shadowing, unused_variable, empty_if, divide_by_zero, unbalanced_assignments)
--[[

  lparser.lua
  Lua 5 parser in Lua
  This file is part of Yueliang.

  Copyright (c) 2005-2007 Kein-Hong Man <khman@users.sf.net>
  The COPYRIGHT file describes the conditions
  under which this software may be distributed.

  See the ChangeLog for more information.

]]

--[[
-- Notes:
-- * some unused C code that were not converted are kept as comments
-- * LUA_COMPAT_VARARG option changed into a comment block
-- * for value/size specific code added, look for 'NOTE: '
--
-- Not implemented:
-- * luaX_newstring not needed by this Lua implementation
-- * luaG_checkcode() in assert is not currently implemented
--
-- Added:
-- * some constants added from various header files
-- * luaY.LUA_QS used in error_expected, check_match (from luaconf.h)
-- * luaY:LUA_QL needed for error messages (from luaconf.h)
-- * luaY:growvector (from lmem.h) -- skeleton only, limit checking
-- * luaY.SHRT_MAX (from <limits.h>) for registerlocalvar
-- * luaY:newproto (from lfunc.c)
-- * luaY:int2fb (from lobject.c)
-- * NOTE: HASARG_MASK, for implementing a VARARG_HASARG bit operation
-- * NOTE: value-specific code for VARARG_NEEDSARG to replace a bitop
--
-- Changed in 5.1.x:
-- * various code changes are not detailed...
-- * names of constants may have changed, e.g. added a LUAI_ prefix
-- * struct expkind: added VKNUM, VVARARG; VCALL's info changed?
-- * struct expdesc: added nval
-- * struct FuncState: upvalues data type changed to upvaldesc
-- * macro hasmultret is new
-- * function checklimit moved to parser from lexer
-- * functions anchor_token, errorlimit, checknext are new
-- * checknext is new, equivalent to 5.0.x's check, see check too
-- * luaY:next and luaY:lookahead moved to lexer
-- * break keyword no longer skipped in luaY:breakstat
-- * function new_localvarstr replaced by new_localvarliteral
-- * registerlocalvar limits local variables to SHRT_MAX
-- * create_local deleted, new_localvarliteral used instead
-- * constant LUAI_MAXUPVALUES increased to 60
-- * constants MAXPARAMS, LUA_MAXPARSERLEVEL, MAXSTACK removed
-- * function interface changed: singlevaraux, singlevar
-- * enterlevel and leavelevel uses nCcalls to track call depth
-- * added a name argument to main entry function, luaY:parser
-- * function luaY_index changed to yindex
-- * luaY:int2fb()'s table size encoding format has been changed
-- * luaY:log2() no longer needed for table constructors
-- * function code_params deleted, functionality folded in parlist
-- * vararg flags handling (is_vararg) changes; also see VARARG_*
-- * LUA_COMPATUPSYNTAX section for old-style upvalues removed
-- * repeatstat() calls chunk() instead of block()
-- * function interface changed: cond, test_then_block
-- * while statement implementation considerably simplified; MAXEXPWHILE
--   and EXTRAEXP no longer required, no limits to the complexity of a
--   while condition
-- * repeat, forbody statement implementation has major changes,
--   mostly due to new scoping behaviour of local variables
-- * OPR_MULT renamed to OPR_MUL
]]

luaY = {}

--[[
-- Expression descriptor
-- * expkind changed to string constants; luaY:assignment was the only
--   function to use a relational operator with this enumeration
-- VVOID       -- no value
-- VNIL        -- no value
-- VTRUE       -- no value
-- VFALSE      -- no value
-- VK          -- info = index of constant in 'k'
-- VKNUM       -- nval = numerical value
-- VLOCAL      -- info = local register
-- VUPVAL,     -- info = index of upvalue in 'upvalues'
-- VGLOBAL     -- info = index of table; aux = index of global name in 'k'
-- VINDEXED    -- info = table register; aux = index register (or 'k')
-- VJMP        -- info = instruction pc
-- VRELOCABLE  -- info = instruction pc
-- VNONRELOC   -- info = result register
-- VCALL       -- info = instruction pc
-- VVARARG     -- info = instruction pc
]]

--[[
-- * expdesc in Lua 5.1.x has a union u and another struct s; this Lua
--   implementation ignores all instances of u and s usage
-- struct expdesc:
--   k  -- (enum: expkind)
--   info, aux -- (int, int)
--   nval -- (lua_Number)
--   t  -- patch list of 'exit when true'
--   f  -- patch list of 'exit when false'
]]

--[[
-- struct upvaldesc:
--   k  -- (lu_byte)
--   info -- (lu_byte)
]]

--[[
-- state needed to generate code for a given function
-- struct FuncState:
--   f  -- current function header (table: Proto)
--   h  -- table to find (and reuse) elements in 'k' (table: Table)
--   prev  -- enclosing function (table: FuncState)
--   ls  -- lexical state (table: LexState)
--   L  -- copy of the Lua state (table: lua_State)
--   bl  -- chain of current blocks (table: BlockCnt)
--   pc  -- next position to code (equivalent to 'ncode')
--   lasttarget   -- 'pc' of last 'jump target'
--   jpc  -- list of pending jumps to 'pc'
--   freereg  -- first free register
--   nk  -- number of elements in 'k'
--   np  -- number of elements in 'p'
--   nlocvars  -- number of elements in 'locvars'
--   nactvar  -- number of active local variables
--   upvalues[LUAI_MAXUPVALUES]  -- upvalues (table: upvaldesc)
--   actvar[LUAI_MAXVARS]  -- declared-variable stack
]]

------------------------------------------------------------------------
-- constants used by parser
-- * picks up duplicate values from luaX if required
------------------------------------------------------------------------

luaY.LUA_QS = luaX.LUA_QS or "'%s'"  -- (from luaconf.h)

luaY.SHRT_MAX = 32767 -- (from <limits.h>)
luaY.LUAI_MAXVARS = 200  -- (luaconf.h)
luaY.LUAI_MAXUPVALUES = 60  -- (luaconf.h)
luaY.MAX_INT = luaX.MAX_INT or 2147483645  -- (from llimits.h)
-- * INT_MAX-2 for 32-bit systems
luaY.LUAI_MAXCCALLS = 200  -- (from luaconf.h)

luaY.VARARG_HASARG = 1  -- (from lobject.h)
-- NOTE: HASARG_MASK is value-specific
luaY.HASARG_MASK = 2 -- this was added for a bitop in parlist()
luaY.VARARG_ISVARARG = 2
-- NOTE: there is some value-specific code that involves VARARG_NEEDSARG
luaY.VARARG_NEEDSARG = 4

luaY.LUA_MULTRET = -1  -- (lua.h)

--[[
-- other functions
]]

------------------------------------------------------------------------
-- LUA_QL describes how error messages quote program elements.
-- CHANGE it if you want a different appearance. (from luaconf.h)
------------------------------------------------------------------------
function luaY:LUA_QL(x)
    return "'"..x.."'"
end

------------------------------------------------------------------------
-- this is a stripped-down luaM_growvector (from lmem.h) which is a
-- macro based on luaM_growaux (in lmem.c); all the following does is
-- reproduce the size limit checking logic of the original function
-- so that error behaviour is identical; all arguments preserved for
-- convenience, even those which are unused
-- * set the t field to nil, since this originally does a sizeof(t)
-- * size (originally a pointer) is never updated, their final values
--   are set by luaY:close_func(), so overall things should still work
------------------------------------------------------------------------
function luaY:growvector(L, v, nelems, size, t, limit, e)
    if nelems >= limit then
        error(e)  -- was luaG_runerror
    end
end

------------------------------------------------------------------------
-- initialize a new function prototype structure (from lfunc.c)
-- * used only in open_func()
------------------------------------------------------------------------
function luaY:newproto(L)
    local f = {} -- Proto
    -- luaC_link(L, obj2gco(f), LUA_TPROTO); /* GC */
    f.k = {}
    f.sizek = 0
    f.p = {}
    f.sizep = 0
    f.code = {}
    f.sizecode = 0
    f.sizelineinfo = 0
    f.sizeupvalues = 0
    f.nups = 0
    f.upvalues = {}
    f.numparams = 0
    f.is_vararg = 0
    f.maxstacksize = 0
    f.lineinfo = {}
    f.sizelocvars = 0
    f.locvars = {}
    f.lineDefined = 0
    f.lastlinedefined = 0
    f.source = nil
    return f
end

------------------------------------------------------------------------
-- converts an integer to a "floating point byte", represented as
-- (eeeeexxx), where the real value is (1xxx) * 2^(eeeee - 1) if
-- eeeee != 0 and (xxx) otherwise.
------------------------------------------------------------------------
function luaY:int2fb(x)
    local e = 0  -- exponent
    while x >= 16 do
        x = math.floor((x + 1) / 2)
        e = e + 1
    end
    if x < 8 then
        return x
    else
        return ((e + 1) * 8) + (x - 8)
    end
end

--[[
-- parser functions
]]

------------------------------------------------------------------------
-- true of the kind of expression produces multiple return values
------------------------------------------------------------------------
function luaY:hasmultret(k)
    return k == "VCALL" or k == "VVARARG"
end

------------------------------------------------------------------------
-- convenience function to access active local i, returns entry
------------------------------------------------------------------------
function luaY:getlocvar(fs, i)
    return fs.f.locvars[ fs.actvar[i] ]
end

------------------------------------------------------------------------
-- check a limit, string m provided as an error message
------------------------------------------------------------------------
function luaY:checklimit(fs, v, l, m)
    if v > l then self:errorlimit(fs, l, m) end
end

--[[
-- nodes for block list (list of active blocks)
-- struct BlockCnt:
--   previous  -- chain (table: BlockCnt)
--   breaklist  -- list of jumps out of this loop
--   nactvar  -- # active local variables outside the breakable structure
--   upval  -- true if some variable in the block is an upvalue (boolean)
--   isbreakable  -- true if 'block' is a loop (boolean)
]]

------------------------------------------------------------------------
-- prototypes for recursive non-terminal functions
------------------------------------------------------------------------
-- prototypes deleted; not required in Lua

------------------------------------------------------------------------
-- reanchor if last token is has a constant string, see close_func()
-- * used only in close_func()
------------------------------------------------------------------------
function luaY:anchor_token(ls)
    if ls.t.token == "TK_NAME" or ls.t.token == "TK_STRING" then
        -- not relevant to Lua implementation of parser
        -- local ts = ls.t.seminfo
        -- luaX_newstring(ls, getstr(ts), ts->tsv.len); /* C */
    end
end

------------------------------------------------------------------------
-- throws a syntax error if token expected is not there
------------------------------------------------------------------------
function luaY:error_expected(ls, token)
    luaX:syntaxerror(ls,
        string.format(self.LUA_QS.." expected", luaX:token2str(ls, token)))
end

------------------------------------------------------------------------
-- prepares error message for display, for limits exceeded
-- * used only in checklimit()
------------------------------------------------------------------------
function luaY:errorlimit(fs, limit, what)
    local msg = (fs.f.linedefined == 0) and
        string.format("main function has more than %d %s", limit, what) or
        string.format("function at line %d has more than %d %s",
            fs.f.linedefined, limit, what)
    luaX:lexerror(fs.ls, msg, 0)
end

------------------------------------------------------------------------
-- tests for a token, returns outcome
-- * return value changed to boolean
------------------------------------------------------------------------
function luaY:testnext(ls, c)
    if ls.t.token == c then
        luaX:next(ls)
        return true
    else
        return false
    end
end

------------------------------------------------------------------------
-- check for existence of a token, throws error if not found
------------------------------------------------------------------------
function luaY:check(ls, c)
    if ls.t.token ~= c then
        self:error_expected(ls, c)
    end
end

------------------------------------------------------------------------
-- verify existence of a token, then skip it
------------------------------------------------------------------------
function luaY:checknext(ls, c)
    self:check(ls, c)
    luaX:next(ls)
end

------------------------------------------------------------------------
-- throws error if condition not matched
------------------------------------------------------------------------
function luaY:check_condition(ls, c, msg)
    if not c then luaX:syntaxerror(ls, msg) end
end

------------------------------------------------------------------------
-- verifies token conditions are met or else throw error
------------------------------------------------------------------------
function luaY:check_match(ls, what, who, where)
    if not self:testnext(ls, what) then
        if where == ls.linenumber then
            self:error_expected(ls, what)
        else
            luaX:syntaxerror(ls, string.format(
                self.LUA_QS.." expected (to close "..self.LUA_QS.." at line %d)",
                luaX:token2str(ls, what), luaX:token2str(ls, who), where))
        end
    end
end

------------------------------------------------------------------------
-- expect that token is a name, return the name
------------------------------------------------------------------------
function luaY:str_checkname(ls)
    self:check(ls, "TK_NAME")
    local ts = ls.t.seminfo
    luaX:next(ls)
    return ts
end

------------------------------------------------------------------------
-- initialize a struct expdesc, expression description data structure
------------------------------------------------------------------------
function luaY:init_exp(e, k, i)
    e.f, e.t = luaK.NO_JUMP, luaK.NO_JUMP
    e.k = k
    e.info = i
end

------------------------------------------------------------------------
-- adds given string s in string pool, sets e as VK
------------------------------------------------------------------------
function luaY:codestring(ls, e, s)
    self:init_exp(e, "VK", luaK:stringK(ls.fs, s))
end

------------------------------------------------------------------------
-- consume a name token, adds it to string pool, sets e as VK
------------------------------------------------------------------------
function luaY:checkname(ls, e)
    self:codestring(ls, e, self:str_checkname(ls))
end

------------------------------------------------------------------------
-- creates struct entry for a local variable
-- * used only in new_localvar()
------------------------------------------------------------------------
function luaY:registerlocalvar(ls, varname)
    local fs = ls.fs
    local f = fs.f
    self:growvector(ls.L, f.locvars, fs.nlocvars, f.sizelocvars,
        nil, self.SHRT_MAX, "too many local variables")
    -- loop to initialize empty f.locvar positions not required
    f.locvars[fs.nlocvars] = {} -- LocVar
    f.locvars[fs.nlocvars].varname = varname
    -- luaC_objbarrier(ls.L, f, varname) /* GC */
    local nlocvars = fs.nlocvars
    fs.nlocvars = fs.nlocvars + 1
    return nlocvars
end

------------------------------------------------------------------------
-- creates a new local variable given a name and an offset from nactvar
-- * used in fornum(), forlist(), parlist(), body()
------------------------------------------------------------------------
function luaY:new_localvarliteral(ls, v, n)
    self:new_localvar(ls, v, n)
end

------------------------------------------------------------------------
-- register a local variable, set in active variable list
------------------------------------------------------------------------
function luaY:new_localvar(ls, name, n)
    local fs = ls.fs
    self:checklimit(fs, fs.nactvar + n + 1, self.LUAI_MAXVARS, "local variables")
    fs.actvar[fs.nactvar + n] = self:registerlocalvar(ls, name)
end

------------------------------------------------------------------------
-- adds nvars number of new local variables, set debug information
------------------------------------------------------------------------
function luaY:adjustlocalvars(ls, nvars)
    local fs = ls.fs
    fs.nactvar = fs.nactvar + nvars
    for i = nvars, 1, -1 do
        self:getlocvar(fs, fs.nactvar - i).startpc = fs.pc
    end
end

------------------------------------------------------------------------
-- removes a number of locals, set debug information
------------------------------------------------------------------------
function luaY:removevars(ls, tolevel)
    local fs = ls.fs
    while fs.nactvar > tolevel do
        fs.nactvar = fs.nactvar - 1
        self:getlocvar(fs, fs.nactvar).endpc = fs.pc
    end
end

------------------------------------------------------------------------
-- returns an existing upvalue index based on the given name, or
-- creates a new upvalue struct entry and returns the new index
-- * used only in singlevaraux()
------------------------------------------------------------------------
function luaY:indexupvalue(fs, name, v)
    local f = fs.f
    for i = 0, f.nups - 1 do
        if fs.upvalues[i].k == v.k and fs.upvalues[i].info == v.info then
            assert(f.upvalues[i] == name)
            return i
        end
    end
    -- new one
    self:checklimit(fs, f.nups + 1, self.LUAI_MAXUPVALUES, "upvalues")
    self:growvector(fs.L, f.upvalues, f.nups, f.sizeupvalues,
        nil, self.MAX_INT, "")
    -- loop to initialize empty f.upvalues positions not required
    f.upvalues[f.nups] = name
    -- luaC_objbarrier(fs->L, f, name); /* GC */
    assert(v.k == "VLOCAL" or v.k == "VUPVAL")
    -- this is a partial copy; only k & info fields used
    fs.upvalues[f.nups] = { k = v.k, info = v.info }
    local nups = f.nups
    f.nups = f.nups + 1
    return nups
end

------------------------------------------------------------------------
-- search the local variable namespace of the given fs for a match
-- * used only in singlevaraux()
------------------------------------------------------------------------
function luaY:searchvar(fs, n)
    for i = fs.nactvar - 1, 0, -1 do
        if n == self:getlocvar(fs, i).varname then
            return i
        end
    end
    return -1  -- not found
end

------------------------------------------------------------------------
-- * mark upvalue flags in function states up to a given level
-- * used only in singlevaraux()
------------------------------------------------------------------------
function luaY:markupval(fs, level)
    local bl = fs.bl
    while bl and bl.nactvar > level do bl = bl.previous end
    if bl then bl.upval = true end
end

------------------------------------------------------------------------
-- handle locals, globals and upvalues and related processing
-- * search mechanism is recursive, calls itself to search parents
-- * used only in singlevar()
------------------------------------------------------------------------
function luaY:singlevaraux(fs, n, var, base)
    if fs == nil then  -- no more levels?
        self:init_exp(var, "VGLOBAL", luaP.NO_REG)  -- default is global variable
        return "VGLOBAL"
    else
        local v = self:searchvar(fs, n)  -- look up at current level
        if v >= 0 then
            self:init_exp(var, "VLOCAL", v)
            if base == 0 then
                self:markupval(fs, v)  -- local will be used as an upval
            end
            return "VLOCAL"
        else  -- not found at current level; try upper one
            if self:singlevaraux(fs.prev, n, var, 0) == "VGLOBAL" then
                return "VGLOBAL"
            end
            var.info = self:indexupvalue(fs, n, var)  -- else was LOCAL or UPVAL
            var.k = "VUPVAL"  -- upvalue in this level
            return "VUPVAL"
        end--if v
    end--if fs
end

------------------------------------------------------------------------
-- consume a name token, creates a variable (global|local|upvalue)
-- * used in prefixexp(), funcname()
------------------------------------------------------------------------
function luaY:singlevar(ls, var)
    local varname = self:str_checkname(ls)
    local fs = ls.fs
    if self:singlevaraux(fs, varname, var, 1) == "VGLOBAL" then
        var.info = luaK:stringK(fs, varname)  -- info points to global name
    end
end

------------------------------------------------------------------------
-- adjust RHS to match LHS in an assignment
-- * used in assignment(), forlist(), localstat()
------------------------------------------------------------------------
function luaY:adjust_assign(ls, nvars, nexps, e)
    local fs = ls.fs
    local extra = nvars - nexps
    if self:hasmultret(e.k) then
        extra = extra + 1  -- includes call itself
        if extra <= 0 then extra = 0 end
        luaK:setreturns(fs, e, extra)  -- last exp. provides the difference
        if extra > 1 then luaK:reserveregs(fs, extra - 1) end
    else
        if e.k ~= "VVOID" then luaK:exp2nextreg(fs, e) end  -- close last expression
        if extra > 0 then
            local reg = fs.freereg
            luaK:reserveregs(fs, extra)
            luaK:_nil(fs, reg, extra)
        end
    end
end

------------------------------------------------------------------------
-- tracks and limits parsing depth, assert check at end of parsing
------------------------------------------------------------------------
function luaY:enterlevel(ls)
    ls.L.nCcalls = ls.L.nCcalls + 1
    if ls.L.nCcalls > self.LUAI_MAXCCALLS then
        luaX:lexerror(ls, "chunk has too many syntax levels", 0)
    end
end

------------------------------------------------------------------------
-- tracks parsing depth, a pair with luaY:enterlevel()
------------------------------------------------------------------------
function luaY:leavelevel(ls)
    ls.L.nCcalls = ls.L.nCcalls - 1
end

------------------------------------------------------------------------
-- enters a code unit, initializes elements
------------------------------------------------------------------------
function luaY:enterblock(fs, bl, isbreakable)
    bl.breaklist = luaK.NO_JUMP
    bl.isbreakable = isbreakable
    bl.nactvar = fs.nactvar
    bl.upval = false
    bl.previous = fs.bl
    fs.bl = bl
    assert(fs.freereg == fs.nactvar)
end

------------------------------------------------------------------------
-- leaves a code unit, close any upvalues
------------------------------------------------------------------------
function luaY:leaveblock(fs)
    local bl = fs.bl
    fs.bl = bl.previous
    self:removevars(fs.ls, bl.nactvar)
    if bl.upval then
        luaK:codeABC(fs, "OP_CLOSE", bl.nactvar, 0, 0)
    end
    -- a block either controls scope or breaks (never both)
    assert(not bl.isbreakable or not bl.upval)
    assert(bl.nactvar == fs.nactvar)
    fs.freereg = fs.nactvar  -- free registers
    luaK:patchtohere(fs, bl.breaklist)
end

------------------------------------------------------------------------
-- implement the instantiation of a function prototype, append list of
-- upvalues after the instantiation instruction
-- * used only in body()
------------------------------------------------------------------------
function luaY:pushclosure(ls, func, v)
    local fs = ls.fs
    local f = fs.f
    self:growvector(ls.L, f.p, fs.np, f.sizep, nil,
        luaP.MAXARG_Bx, "constant table overflow")
    -- loop to initialize empty f.p positions not required
    f.p[fs.np] = func.f
    fs.np = fs.np + 1
    -- luaC_objbarrier(ls->L, f, func->f); /* C */
    self:init_exp(v, "VRELOCABLE", luaK:codeABx(fs, "OP_CLOSURE", 0, fs.np - 1))
    for i = 0, func.f.nups - 1 do
        local o = (func.upvalues[i].k == "VLOCAL") and "OP_MOVE" or "OP_GETUPVAL"
        luaK:codeABC(fs, o, 0, func.upvalues[i].info, 0)
    end
end

------------------------------------------------------------------------
-- opening of a function
------------------------------------------------------------------------
function luaY:open_func(ls, fs)
    local L = ls.L
    local f = self:newproto(ls.L)
    fs.f = f
    fs.prev = ls.fs  -- linked list of funcstates
    fs.ls = ls
    fs.L = L
    ls.fs = fs
    fs.pc = 0
    fs.lasttarget = -1
    fs.jpc = luaK.NO_JUMP
    fs.freereg = 0
    fs.nk = 0
    fs.np = 0
    fs.nlocvars = 0
    fs.nactvar = 0
    fs.bl = nil
    f.source = ls.source
    f.maxstacksize = 2  -- registers 0/1 are always valid
    fs.h = {}  -- constant table; was luaH_new call
    -- anchor table of constants and prototype (to avoid being collected)
    -- sethvalue2s(L, L->top, fs->h); incr_top(L); /* C */
    -- setptvalue2s(L, L->top, f); incr_top(L);
end

------------------------------------------------------------------------
-- closing of a function
------------------------------------------------------------------------
function luaY:close_func(ls)
    local L = ls.L
    local fs = ls.fs
    local f = fs.f
    self:removevars(ls, 0)
    luaK:ret(fs, 0, 0)  -- final return
    -- luaM_reallocvector deleted for f->code, f->lineinfo, f->k, f->p,
    -- f->locvars, f->upvalues; not required for Lua table arrays
    f.sizecode = fs.pc
    f.sizelineinfo = fs.pc
    f.sizek = fs.nk
    f.sizep = fs.np
    f.sizelocvars = fs.nlocvars
    f.sizeupvalues = f.nups
    --assert(luaG_checkcode(f))  -- currently not implemented
    assert(fs.bl == nil)
    ls.fs = fs.prev
    -- the following is not required for this implementation; kept here
    -- for completeness
    -- L->top -= 2;  /* remove table and prototype from the stack */
    -- last token read was anchored in defunct function; must reanchor it
    if fs then self:anchor_token(ls) end
end

------------------------------------------------------------------------
-- parser initialization function
-- * note additional sub-tables needed for LexState, FuncState
------------------------------------------------------------------------
function luaY:parser(L, z, buff, name)
    local lexstate = {}  -- LexState
    lexstate.t = {}
    lexstate.lookahead = {}
    local funcstate = {}  -- FuncState
    funcstate.upvalues = {}
    funcstate.actvar = {}
    -- the following nCcalls initialization added for convenience
    L.nCcalls = 0
    lexstate.buff = buff
    luaX:setinput(L, lexstate, z, name)
    self:open_func(lexstate, funcstate)
    funcstate.f.is_vararg = self.VARARG_ISVARARG  -- main func. is always vararg
    luaX:next(lexstate)  -- read first token
    self:chunk(lexstate)
    self:check(lexstate, "TK_EOS")
    self:close_func(lexstate)
    assert(funcstate.prev == nil)
    assert(funcstate.f.nups == 0)
    assert(lexstate.fs == nil)
    return funcstate.f
end

--[[
-- GRAMMAR RULES
]]

------------------------------------------------------------------------
-- parse a function name suffix, for function call specifications
-- * used in primaryexp(), funcname()
------------------------------------------------------------------------
function luaY:field(ls, v)
    -- field -> ['.' | ':'] NAME
    local fs = ls.fs
    local key = {}  -- expdesc
    luaK:exp2anyreg(fs, v)
    luaX:next(ls)  -- skip the dot or colon
    self:checkname(ls, key)
    luaK:indexed(fs, v, key)
end

------------------------------------------------------------------------
-- parse a table indexing suffix, for constructors, expressions
-- * used in recfield(), primaryexp()
------------------------------------------------------------------------
function luaY:yindex(ls, v)
    -- index -> '[' expr ']'
    luaX:next(ls)  -- skip the '['
    self:expr(ls, v)
    luaK:exp2val(ls.fs, v)
    self:checknext(ls, "]")
end

--[[
-- Rules for Constructors
]]

--[[
-- struct ConsControl:
--   v  -- last list item read (table: struct expdesc)
--   t  -- table descriptor (table: struct expdesc)
--   nh  -- total number of 'record' elements
--   na  -- total number of array elements
--   tostore  -- number of array elements pending to be stored
]]

------------------------------------------------------------------------
-- parse a table record (hash) field
-- * used in constructor()
------------------------------------------------------------------------
function luaY:recfield(ls, cc)
    -- recfield -> (NAME | '['exp1']') = exp1
    local fs = ls.fs
    local reg = ls.fs.freereg
    local key, val = {}, {}  -- expdesc
    if ls.t.token == "TK_NAME" then
        self:checklimit(fs, cc.nh, self.MAX_INT, "items in a constructor")
        self:checkname(ls, key)
    else  -- ls->t.token == '['
        self:yindex(ls, key)
    end
    cc.nh = cc.nh + 1
    self:checknext(ls, "=")
    local rkkey = luaK:exp2RK(fs, key)
    self:expr(ls, val)
    luaK:codeABC(fs, "OP_SETTABLE", cc.t.info, rkkey, luaK:exp2RK(fs, val))
    fs.freereg = reg  -- free registers
end

------------------------------------------------------------------------
-- emit a set list instruction if enough elements (LFIELDS_PER_FLUSH)
-- * used in constructor()
------------------------------------------------------------------------
function luaY:closelistfield(fs, cc)
    if cc.v.k == "VVOID" then return end  -- there is no list item
    luaK:exp2nextreg(fs, cc.v)
    cc.v.k = "VVOID"
    if cc.tostore == luaP.LFIELDS_PER_FLUSH then
        luaK:setlist(fs, cc.t.info, cc.na, cc.tostore)  -- flush
        cc.tostore = 0  -- no more items pending
    end
end

------------------------------------------------------------------------
-- emit a set list instruction at the end of parsing list constructor
-- * used in constructor()
------------------------------------------------------------------------
function luaY:lastlistfield(fs, cc)
    if cc.tostore == 0 then return end
    if self:hasmultret(cc.v.k) then
        luaK:setmultret(fs, cc.v)
        luaK:setlist(fs, cc.t.info, cc.na, self.LUA_MULTRET)
        cc.na = cc.na - 1  -- do not count last expression (unknown number of elements)
    else
        if cc.v.k ~= "VVOID" then
            luaK:exp2nextreg(fs, cc.v)
        end
        luaK:setlist(fs, cc.t.info, cc.na, cc.tostore)
    end
end

------------------------------------------------------------------------
-- parse a table list (array) field
-- * used in constructor()
------------------------------------------------------------------------
function luaY:listfield(ls, cc)
    self:expr(ls, cc.v)
    self:checklimit(ls.fs, cc.na, self.MAX_INT, "items in a constructor")
    cc.na = cc.na + 1
    cc.tostore = cc.tostore + 1
end

------------------------------------------------------------------------
-- parse a table constructor
-- * used in funcargs(), simpleexp()
------------------------------------------------------------------------
function luaY:constructor(ls, t)
    -- constructor -> '{' [ field { fieldsep field } [ fieldsep ] ] '}'
    -- field -> recfield | listfield
    -- fieldsep -> ',' | ';'
    local fs = ls.fs
    local line = ls.linenumber
    local pc = luaK:codeABC(fs, "OP_NEWTABLE", 0, 0, 0)
    local cc = {}  -- ConsControl
    cc.v = {}
    cc.na, cc.nh, cc.tostore = 0, 0, 0
    cc.t = t
    self:init_exp(t, "VRELOCABLE", pc)
    self:init_exp(cc.v, "VVOID", 0)  -- no value (yet)
    luaK:exp2nextreg(ls.fs, t)  -- fix it at stack top (for gc)
    self:checknext(ls, "{")
    repeat
        assert(cc.v.k == "VVOID" or cc.tostore > 0)
        if ls.t.token == "}" then break end
        self:closelistfield(fs, cc)
        local c = ls.t.token

        if c == "TK_NAME" then  -- may be listfields or recfields
            luaX:lookahead(ls)
            if ls.lookahead.token ~= "=" then  -- expression?
                self:listfield(ls, cc)
            else
                self:recfield(ls, cc)
            end
        elseif c == "[" then  -- constructor_item -> recfield
            self:recfield(ls, cc)
        else  -- constructor_part -> listfield
            self:listfield(ls, cc)
        end
    until not self:testnext(ls, ",") and not self:testnext(ls, ";")
    self:check_match(ls, "}", "{", line)
    self:lastlistfield(fs, cc)
    luaP:SETARG_B(fs.f.code[pc], self:int2fb(cc.na)) -- set initial array size
    luaP:SETARG_C(fs.f.code[pc], self:int2fb(cc.nh)) -- set initial table size
end

------------------------------------------------------------------------
-- parse the arguments (parameters) of a function declaration
-- * used in body()
------------------------------------------------------------------------
function luaY:parlist(ls)
    -- parlist -> [ param { ',' param } ]
    local fs = ls.fs
    local f = fs.f
    local nparams = 0
    f.is_vararg = 0
    if ls.t.token ~= ")" then  -- is 'parlist' not empty?
        repeat
            local c = ls.t.token
            if c == "TK_NAME" then  -- param -> NAME
                self:new_localvar(ls, self:str_checkname(ls), nparams)
                nparams = nparams + 1
            elseif c == "TK_DOTS" then  -- param -> `...'
                luaX:next(ls)
                -- #if defined(LUA_COMPAT_VARARG)
                -- use `arg' as default name
                self:new_localvarliteral(ls, "arg", nparams)
                nparams = nparams + 1
                f.is_vararg = self.VARARG_HASARG + self.VARARG_NEEDSARG
                -- #endif
                f.is_vararg = f.is_vararg + self.VARARG_ISVARARG
            else
                luaX:syntaxerror(ls, "<name> or "..self:LUA_QL("...").." expected")
            end
        until f.is_vararg ~= 0 or not self:testnext(ls, ",")
    end--if
    self:adjustlocalvars(ls, nparams)
    -- NOTE: the following works only when HASARG_MASK is 2!
    f.numparams = fs.nactvar - (f.is_vararg % self.HASARG_MASK)
    luaK:reserveregs(fs, fs.nactvar)  -- reserve register for parameters
end

------------------------------------------------------------------------
-- parse function declaration body
-- * used in simpleexp(), localfunc(), funcstat()
------------------------------------------------------------------------
function luaY:body(ls, e, needself, line)
    -- body ->  '(' parlist ')' chunk END
    local new_fs = {}  -- FuncState
    new_fs.upvalues = {}
    new_fs.actvar = {}
    self:open_func(ls, new_fs)
    new_fs.f.lineDefined = line
    self:checknext(ls, "(")
    if needself then
        self:new_localvarliteral(ls, "self", 0)
        self:adjustlocalvars(ls, 1)
    end
    self:parlist(ls)
    self:checknext(ls, ")")
    self:chunk(ls)
    new_fs.f.lastlinedefined = ls.linenumber
    self:check_match(ls, "TK_END", "TK_FUNCTION", line)
    self:close_func(ls)
    self:pushclosure(ls, new_fs, e)
end

------------------------------------------------------------------------
-- parse a list of comma-separated expressions
-- * used is multiple locations
------------------------------------------------------------------------
function luaY:explist1(ls, v)
    -- explist1 -> expr { ',' expr }
    local n = 1  -- at least one expression
    self:expr(ls, v)
    while self:testnext(ls, ",") do
        luaK:exp2nextreg(ls.fs, v)
        self:expr(ls, v)
        n = n + 1
    end
    return n
end

------------------------------------------------------------------------
-- parse the parameters of a function call
-- * contrast with parlist(), used in function declarations
-- * used in primaryexp()
------------------------------------------------------------------------
function luaY:funcargs(ls, f)
    local fs = ls.fs
    local args = {}  -- expdesc
    local nparams
    local line = ls.linenumber
    local c = ls.t.token
    if c == "(" then  -- funcargs -> '(' [ explist1 ] ')'
        if line ~= ls.lastline then
            luaX:syntaxerror(ls, "ambiguous syntax (function call x new statement)")
        end
        luaX:next(ls)
        if ls.t.token == ")" then  -- arg list is empty?
            args.k = "VVOID"
        else
            self:explist1(ls, args)
            luaK:setmultret(fs, args)
        end
        self:check_match(ls, ")", "(", line)
    elseif c == "{" then  -- funcargs -> constructor
        self:constructor(ls, args)
    elseif c == "TK_STRING" then  -- funcargs -> STRING
        self:codestring(ls, args, ls.t.seminfo)
        luaX:next(ls)  -- must use 'seminfo' before 'next'
    else
        luaX:syntaxerror(ls, "function arguments expected")
        return
    end
    assert(f.k == "VNONRELOC")
    local base = f.info  -- base register for call
    if self:hasmultret(args.k) then
        nparams = self.LUA_MULTRET  -- open call
    else
        if args.k ~= "VVOID" then
            luaK:exp2nextreg(fs, args)  -- close last argument
        end
        nparams = fs.freereg - (base + 1)
    end
    self:init_exp(f, "VCALL", luaK:codeABC(fs, "OP_CALL", base, nparams + 1, 2))
    luaK:fixline(fs, line)
    fs.freereg = base + 1  -- call remove function and arguments and leaves
    -- (unless changed) one result
end

--[[
-- Expression parsing
]]

------------------------------------------------------------------------
-- parses an expression in parentheses or a single variable
-- * used in primaryexp()
------------------------------------------------------------------------
function luaY:prefixexp(ls, v)
    -- prefixexp -> NAME | '(' expr ')'
    local c = ls.t.token
    if c == "(" then
        local line = ls.linenumber
        luaX:next(ls)
        self:expr(ls, v)
        self:check_match(ls, ")", "(", line)
        luaK:dischargevars(ls.fs, v)
    elseif c == "TK_NAME" then
        self:singlevar(ls, v)
    else
        luaX:syntaxerror(ls, "unexpected symbol")
    end--if c
    return
end

------------------------------------------------------------------------
-- parses a prefixexp (an expression in parentheses or a single variable)
-- or a function call specification
-- * used in simpleexp(), assignment(), exprstat()
------------------------------------------------------------------------
function luaY:primaryexp(ls, v)
    -- primaryexp ->
    --    prefixexp { '.' NAME | '[' exp ']' | ':' NAME funcargs | funcargs }
    local fs = ls.fs
    self:prefixexp(ls, v)
    while true do
        local c = ls.t.token
        if c == "." then  -- field
            self:field(ls, v)
        elseif c == "[" then  -- '[' exp1 ']'
            local key = {}  -- expdesc
            luaK:exp2anyreg(fs, v)
            self:yindex(ls, key)
            luaK:indexed(fs, v, key)
        elseif c == ":" then  -- ':' NAME funcargs
            local key = {}  -- expdesc
            luaX:next(ls)
            self:checkname(ls, key)
            luaK:_self(fs, v, key)
            self:funcargs(ls, v)
        elseif c == "(" or c == "TK_STRING" or c == "{" then  -- funcargs
            luaK:exp2nextreg(fs, v)
            self:funcargs(ls, v)
        else
            return
        end--if c
    end--while
end

------------------------------------------------------------------------
-- parses general expression types, constants handled here
-- * used in subexpr()
------------------------------------------------------------------------
function luaY:simpleexp(ls, v)
    -- simpleexp -> NUMBER | STRING | NIL | TRUE | FALSE | ... |
    --              constructor | FUNCTION body | primaryexp
    local c = ls.t.token
    if c == "TK_NUMBER" then
        self:init_exp(v, "VKNUM", 0)
        v.nval = ls.t.seminfo
    elseif c == "TK_STRING" then
        self:codestring(ls, v, ls.t.seminfo)
    elseif c == "TK_NIL" then
        self:init_exp(v, "VNIL", 0)
    elseif c == "TK_TRUE" then
        self:init_exp(v, "VTRUE", 0)
    elseif c == "TK_FALSE" then
        self:init_exp(v, "VFALSE", 0)
    elseif c == "TK_DOTS" then  -- vararg
        local fs = ls.fs
        self:check_condition(ls, fs.f.is_vararg ~= 0,
            "cannot use "..self:LUA_QL("...").." outside a vararg function");
        -- NOTE: the following substitutes for a bitop, but is value-specific
        local is_vararg = fs.f.is_vararg
        if is_vararg >= self.VARARG_NEEDSARG then
            fs.f.is_vararg = is_vararg - self.VARARG_NEEDSARG  -- don't need 'arg'
        end
        self:init_exp(v, "VVARARG", luaK:codeABC(fs, "OP_VARARG", 0, 1, 0))
    elseif c == "{" then  -- constructor
        self:constructor(ls, v)
        return
    elseif c == "TK_FUNCTION" then
        luaX:next(ls)
        self:body(ls, v, false, ls.linenumber)
        return
    else
        self:primaryexp(ls, v)
        return
    end--if c
    luaX:next(ls)
end

------------------------------------------------------------------------
-- Translates unary operators tokens if found, otherwise returns
-- OPR_NOUNOPR. getunopr() and getbinopr() are used in subexpr().
-- * used in subexpr()
------------------------------------------------------------------------
function luaY:getunopr(op)
    if op == "TK_NOT" then
        return "OPR_NOT"
    elseif op == "-" then
        return "OPR_MINUS"
    elseif op == "#" then
        return "OPR_LEN"
    else
        return "OPR_NOUNOPR"
    end
end

------------------------------------------------------------------------
-- Translates binary operator tokens if found, otherwise returns
-- OPR_NOBINOPR. Code generation uses OPR_* style tokens.
-- * used in subexpr()
------------------------------------------------------------------------
luaY.getbinopr_table = {
    ["+"] = "OPR_ADD",
    ["-"] = "OPR_SUB",
    ["*"] = "OPR_MUL",
    ["/"] = "OPR_DIV",
    ["%"] = "OPR_MOD",
    ["^"] = "OPR_POW",
    ["TK_CONCAT"] = "OPR_CONCAT",
    ["TK_NE"] = "OPR_NE",
    ["TK_EQ"] = "OPR_EQ",
    ["<"] = "OPR_LT",
    ["TK_LE"] = "OPR_LE",
    [">"] = "OPR_GT",
    ["TK_GE"] = "OPR_GE",
    ["TK_AND"] = "OPR_AND",
    ["TK_OR"] = "OPR_OR",
}
function luaY:getbinopr(op)
    local opr = self.getbinopr_table[op]
    if opr then return opr else return "OPR_NOBINOPR" end
end

------------------------------------------------------------------------
-- // Luau compound operator translation
-- Also the concat operator is an odd one out, concatting uses a different type of operation
-- because concatting concats a range of operators, I guess its an optimisation or something
-- ccuser44 added this array, but never actually implemented it (?), so moo1210 did. 
------------------------------------------------------------------------
luaY.COMPOUND_OP_TRANSLATE = {
    TK_ASSIGN_ADD = "OP_ADD",
    TK_ASSIGN_SUB = "OP_SUB",
    TK_ASSIGN_MUL = "OP_MUL",
    TK_ASSIGN_DIV = "OP_DIV",
    TK_ASSIGN_MOD = "OP_MOD",
    TK_ASSIGN_POW = "OP_POW",
}
function luaY:getcompopr(op)
    local opr = self.COMPOUND_OP_TRANSLATE[op]
    if opr then return opr else return "OP_NOCOMOPR" end
end


------------------------------------------------------------------------
-- the following priority table consists of pairs of left/right values
-- for binary operators (was a static const struct); grep for ORDER OPR
-- * the following struct is replaced:
--   static const struct {
--     lu_byte left;  /* left priority for each binary operator */
--     lu_byte right; /* right priority */
--   } priority[] = {  /* ORDER OPR */
------------------------------------------------------------------------
luaY.priority = {
    {6, 6}, {6, 6}, {7, 7}, {7, 7}, {7, 7}, -- `+' `-' `/' `%'
    {10, 9}, {5, 4},                 -- power and concat (right associative)
    {3, 3}, {3, 3},                  -- equality
    {3, 3}, {3, 3}, {3, 3}, {3, 3},  -- order
    {2, 2}, {1, 1}                   -- logical (and/or)
}

luaY.UNARY_PRIORITY = 8  -- priority for unary operators

------------------------------------------------------------------------
-- Parse subexpressions. Includes handling of unary operators and binary
-- operators. A subexpr is given the rhs priority level of the operator
-- immediately left of it, if any (limit is -1 if none,) and if a binop
-- is found, limit is compared with the lhs priority level of the binop
-- in order to determine which executes first.
------------------------------------------------------------------------

------------------------------------------------------------------------
-- subexpr -> (simpleexp | unop subexpr) { binop subexpr }
-- where 'binop' is any binary operator with a priority higher than 'limit'
-- * for priority lookups with self.priority[], 1=left and 2=right
-- * recursively called
-- * used in expr()
------------------------------------------------------------------------
function luaY:subexpr(ls, v, limit)
    self:enterlevel(ls)
    local uop = self:getunopr(ls.t.token)
    if uop ~= "OPR_NOUNOPR" then
        luaX:next(ls)
        self:subexpr(ls, v, self.UNARY_PRIORITY)
        luaK:prefix(ls.fs, uop, v)
    else
        self:simpleexp(ls, v)
    end
    -- expand while operators have priorities higher than 'limit'
    local op = self:getbinopr(ls.t.token)
    while op ~= "OPR_NOBINOPR" and self.priority[luaK.BinOpr[op] + 1][1] > limit do
        local v2 = {}  -- expdesc
        luaX:next(ls)
        luaK:infix(ls.fs, op, v)
        -- read sub-expression with higher priority
        local nextop = self:subexpr(ls, v2, self.priority[luaK.BinOpr[op] + 1][2])
        luaK:posfix(ls.fs, op, v, v2)
        op = nextop
    end
    self:leavelevel(ls)
    return op  -- return first untreated operator
end

------------------------------------------------------------------------
-- Expression parsing starts here. Function subexpr is entered with the
-- left operator (which is non-existent) priority of -1, which is lower
-- than all actual operators. Expr information is returned in parm v.
-- * used in multiple locations
------------------------------------------------------------------------
function luaY:expr(ls, v)
    self:subexpr(ls, v, 0)
end

-- }====================================================================

--[[
-- Rules for Statements
]]

------------------------------------------------------------------------
-- checks next token, used as a look-ahead
-- * returns boolean instead of 0|1
-- * used in retstat(), chunk()
------------------------------------------------------------------------
function luaY:block_follow(token)
    if token == "TK_ELSE" or token == "TK_ELSEIF" or token == "TK_END"
        or token == "TK_UNTIL" or token == "TK_EOS" then
        return true
    else
        return false
    end
end

------------------------------------------------------------------------
-- parse a code block or unit
-- * used in multiple functions
------------------------------------------------------------------------
function luaY:block(ls)
    -- block -> chunk
    local fs = ls.fs
    local bl = {}  -- BlockCnt
    self:enterblock(fs, bl, false)
    self:chunk(ls)
    assert(bl.breaklist == luaK.NO_JUMP)
    self:leaveblock(fs)
end

------------------------------------------------------------------------
-- structure to chain all variables in the left-hand side of an
-- assignment
-- struct LHS_assign:
--   prev  -- (table: struct LHS_assign)
--   v  -- variable (global, local, upvalue, or indexed) (table: expdesc)
------------------------------------------------------------------------

------------------------------------------------------------------------
-- check whether, in an assignment to a local variable, the local variable
-- is needed in a previous assignment (to a table). If so, save original
-- local value in a safe place and use this safe copy in the previous
-- assignment.
-- * used in assignment()
------------------------------------------------------------------------
function luaY:check_conflict(ls, lh, v)
    local fs = ls.fs
    local extra = fs.freereg  -- eventual position to save local variable
    local conflict = false
    while lh do
        if lh.v.k == "VINDEXED" then
            if lh.v.info == v.info then  -- conflict?
                conflict = true
                lh.v.info = extra  -- previous assignment will use safe copy
            end
            if lh.v.aux == v.info then  -- conflict?
                conflict = true
                lh.v.aux = extra  -- previous assignment will use safe copy
            end
        end
        lh = lh.prev
    end
    if conflict then
        luaK:codeABC(fs, "OP_MOVE", fs.freereg, v.info, 0)  -- make copy
        luaK:reserveregs(fs, 1)
    end
end

------------------------------------------------------------------------
-- parse a variable assignment sequence
-- * recursively called
-- * used in exprstat()
------------------------------------------------------------------------
function luaY:assignment(ls, lh, nvars)
    local e = {}  -- expdesc
    -- test was: VLOCAL <= lh->v.k && lh->v.k <= VINDEXED
    local c = lh.v.k
    self:check_condition(ls, c == "VLOCAL" or c == "VUPVAL" or c == "VGLOBAL"
        or c == "VINDEXED", "syntax error")
    if self:testnext(ls, ",") then  -- assignment -> ',' primaryexp assignment
        local nv = {}  -- LHS_assign
        nv.v = {}
        nv.prev = lh
        self:primaryexp(ls, nv.v)
        if nv.v.k == "VLOCAL" then
            self:check_conflict(ls, lh, nv.v)
        end
        self:checklimit(ls.fs, nvars, self.LUAI_MAXCCALLS - ls.L.nCcalls,
            "variables in assignment")
        self:assignment(ls, nv, nvars + 1)
    else  -- assignment -> '=' explist1
        local compOpr = self:getcompopr(ls.t.token)
        if compOpr ~= "OP_NOCOMOPR" then
            luaX:next(ls)
        else
            self:checknext(ls, "=")
        end
        local nexps = self:explist1(ls, e)
        if nexps ~= nvars then
            self:adjust_assign(ls, nvars, nexps, e)
            if nexps > nvars then
                ls.fs.freereg = ls.fs.freereg - (nexps - nvars)  -- remove extra values
            end
        else
            luaK:setoneret(ls.fs, e)  -- close last expression
            if compOpr ~= "OP_NOCOMOPR" then
                luaK:exp2val(ls.fs, lh.v)
                luaK:exp2val(ls.fs, e)
                luaK:codearith(ls.fs, compOpr, lh.v, e)
            end
            luaK:storevar(ls.fs, lh.v, e)
            return  -- avoid default
        end
    end
    self:init_exp(e, "VNONRELOC", ls.fs.freereg - 1)  -- default assignment
    luaK:storevar(ls.fs, lh.v, e)
end

------------------------------------------------------------------------
-- parse condition in a repeat statement or an if control structure
-- * used in repeatstat(), test_then_block()
------------------------------------------------------------------------
function luaY:cond(ls)
    -- cond -> exp
    local v = {}  -- expdesc
    self:expr(ls, v)  -- read condition
    if v.k == "VNIL" then v.k = "VFALSE" end  -- 'falses' are all equal here
    luaK:goiftrue(ls.fs, v)
    return v.f
end

------------------------------------------------------------------------
-- parse a break statement
-- * used in statements()
------------------------------------------------------------------------
function luaY:breakstat(ls)
    -- stat -> BREAK
    local fs = ls.fs
    local bl = fs.bl
    local upval = false
    while bl and not bl.isbreakable do
        if bl.upval then upval = true end
        bl = bl.previous
    end
    if not bl then
        luaX:syntaxerror(ls, "no loop to break")
    end
    if upval then
        luaK:codeABC(fs, "OP_CLOSE", bl.nactvar, 0, 0)
    end
    bl.breaklist = luaK:concat(fs, bl.breaklist, luaK:jump(fs))
end

------------------------------------------------------------------------
-- parse a continue statement
-- * used in statements()
------------------------------------------------------------------------
function luaY:continuestat(ls)
    -- stat -> CONTINUE
    local fs = ls.fs
    local bl = fs.bl
    local upval = false
    while bl and not bl.isbreakable do
        if bl.upval then upval = true end
        bl = bl.previous
    end
    if not bl then
        luaX:syntaxerror(ls, "no loop to continue")
    end
    if upval then
        luaK:codeABC(fs, "OP_CLOSE", bl.nactvar, 0, 0)
    end
    luaK:codeAsBx(fs, "OP_JMP", 0, bl.breaklist.previous) -- This is correct from what I can tell from compiling Luau bytecode and testing it
end

------------------------------------------------------------------------
-- parse a while-do control structure, body processed by block()
-- * with dynamic array sizes, MAXEXPWHILE + EXTRAEXP limits imposed by
--   the function's implementation can be removed
-- * used in statements()
------------------------------------------------------------------------
function luaY:whilestat(ls, line)
    -- whilestat -> WHILE cond DO block END
    local fs = ls.fs
    local bl = {}  -- BlockCnt
    luaX:next(ls)  -- skip WHILE
    local whileinit = luaK:getlabel(fs)
    local condexit = self:cond(ls)
    self:enterblock(fs, bl, true)
    self:checknext(ls, "TK_DO")
    self:block(ls)
    luaK:patchlist(fs, luaK:jump(fs), whileinit)
    self:check_match(ls, "TK_END", "TK_WHILE", line)
    self:leaveblock(fs)
    luaK:patchtohere(fs, condexit)  -- false conditions finish the loop
end

------------------------------------------------------------------------
-- parse a repeat-until control structure, body parsed by chunk()
-- * used in statements()
------------------------------------------------------------------------
function luaY:repeatstat(ls, line)
    -- repeatstat -> REPEAT block UNTIL cond
    local fs = ls.fs
    local repeat_init = luaK:getlabel(fs)
    local bl1, bl2 = {}, {}  -- BlockCnt
    self:enterblock(fs, bl1, true)  -- loop block
    self:enterblock(fs, bl2, false)  -- scope block
    luaX:next(ls)  -- skip REPEAT
    self:chunk(ls)
    self:check_match(ls, "TK_UNTIL", "TK_REPEAT", line)
    local condexit = self:cond(ls)  -- read condition (inside scope block)
    if not bl2.upval then  -- no upvalues?
        self:leaveblock(fs)  -- finish scope
        luaK:patchlist(ls.fs, condexit, repeat_init)  -- close the loop
    else  -- complete semantics when there are upvalues
        self:breakstat(ls)  -- if condition then break
        luaK:patchtohere(ls.fs, condexit)  -- else...
        self:leaveblock(fs)  -- finish scope...
        luaK:patchlist(ls.fs, luaK:jump(fs), repeat_init)  -- and repeat
    end
    self:leaveblock(fs)  -- finish loop
end

------------------------------------------------------------------------
-- parse the single expressions needed in numerical for loops
-- * used in fornum()
------------------------------------------------------------------------
function luaY:exp1(ls)
    local e = {}  -- expdesc
    self:expr(ls, e)
    local k = e.k
    luaK:exp2nextreg(ls.fs, e)
    return k
end

------------------------------------------------------------------------
-- parse a for loop body for both versions of the for loop
-- * used in fornum(), forlist()
------------------------------------------------------------------------
function luaY:forbody(ls, base, line, nvars, isnum)
    -- forbody -> DO block
    local bl = {}  -- BlockCnt
    local fs = ls.fs
    self:adjustlocalvars(ls, 3)  -- control variables
    self:checknext(ls, "TK_DO")
    local prep = isnum and luaK:codeAsBx(fs, "OP_FORPREP", base, luaK.NO_JUMP)
        or luaK:jump(fs)
    self:enterblock(fs, bl, false)  -- scope for declared variables
    self:adjustlocalvars(ls, nvars)
    luaK:reserveregs(fs, nvars)
    self:block(ls)
    self:leaveblock(fs)  -- end of scope for declared variables
    luaK:patchtohere(fs, prep)
    local endfor = isnum and luaK:codeAsBx(fs, "OP_FORLOOP", base, luaK.NO_JUMP)
        or luaK:codeABC(fs, "OP_TFORLOOP", base, 0, nvars)
    luaK:fixline(fs, line)  -- pretend that `OP_FOR' starts the loop
    luaK:patchlist(fs, isnum and endfor or luaK:jump(fs), prep + 1)
end

------------------------------------------------------------------------
-- parse a numerical for loop, calls forbody()
-- * used in forstat()
------------------------------------------------------------------------
function luaY:fornum(ls, varname, line)
    -- fornum -> NAME = exp1,exp1[,exp1] forbody
    local fs = ls.fs
    local base = fs.freereg
    self:new_localvarliteral(ls, "(for index)", 0)
    self:new_localvarliteral(ls, "(for limit)", 1)
    self:new_localvarliteral(ls, "(for step)", 2)
    self:new_localvar(ls, varname, 3)
    self:checknext(ls, '=')
    self:exp1(ls)  -- initial value
    self:checknext(ls, ",")
    self:exp1(ls)  -- limit
    if self:testnext(ls, ",") then
        self:exp1(ls)  -- optional step
    else  -- default step = 1
        luaK:codeABx(fs, "OP_LOADK", fs.freereg, luaK:numberK(fs, 1))
        luaK:reserveregs(fs, 1)
    end
    self:forbody(ls, base, line, 1, true)
end

------------------------------------------------------------------------
-- parse a generic for loop, calls forbody()
-- * used in forstat()
------------------------------------------------------------------------
function luaY:forlist(ls, indexname)
    -- forlist -> NAME {,NAME} IN explist1 forbody
    local fs = ls.fs
    local e = {}  -- expdesc
    local nvars = 0
    local base = fs.freereg
    -- create control variables
    self:new_localvarliteral(ls, "(for generator)", nvars)
    nvars = nvars + 1
    self:new_localvarliteral(ls, "(for state)", nvars)
    nvars = nvars + 1
    self:new_localvarliteral(ls, "(for control)", nvars)
    nvars = nvars + 1
    -- create declared variables
    self:new_localvar(ls, indexname, nvars)
    nvars = nvars + 1
    while self:testnext(ls, ",") do
        self:new_localvar(ls, self:str_checkname(ls), nvars)
        nvars = nvars + 1
    end
    self:checknext(ls, "TK_IN")
    local line = ls.linenumber
    self:adjust_assign(ls, 3, self:explist1(ls, e), e)
    luaK:checkstack(fs, 3)  -- extra space to call generator
    self:forbody(ls, base, line, nvars - 3, false)
end

------------------------------------------------------------------------
-- initial parsing for a for loop, calls fornum() or forlist()
-- * used in statements()
------------------------------------------------------------------------
function luaY:forstat(ls, line)
    -- forstat -> FOR (fornum | forlist) END
    local fs = ls.fs
    local bl = {}  -- BlockCnt
    self:enterblock(fs, bl, true)  -- scope for loop and control variables
    luaX:next(ls)  -- skip `for'
    local varname = self:str_checkname(ls)  -- first variable name
    local c = ls.t.token
    if c == "=" then
        self:fornum(ls, varname, line)
    elseif c == "," or c == "TK_IN" then
        self:forlist(ls, varname)
    else
        luaX:syntaxerror(ls, self:LUA_QL("=").." or "..self:LUA_QL("in").." expected")
    end
    self:check_match(ls, "TK_END", "TK_FOR", line)
    self:leaveblock(fs)  -- loop scope (`break' jumps to this point)
end

------------------------------------------------------------------------
-- parse part of an if control structure, including the condition
-- * used in ifstat()
------------------------------------------------------------------------
function luaY:test_then_block(ls)
    -- test_then_block -> [IF | ELSEIF] cond THEN block
    luaX:next(ls)  -- skip IF or ELSEIF
    local condexit = self:cond(ls)
    self:checknext(ls, "TK_THEN")
    self:block(ls)  -- `then' part
    return condexit
end

------------------------------------------------------------------------
-- parse an if control structure
-- * used in statements()
------------------------------------------------------------------------
function luaY:ifstat(ls, line)
    -- ifstat -> IF cond THEN block {ELSEIF cond THEN block} [ELSE block] END
    local fs = ls.fs
    local escapelist = luaK.NO_JUMP
    local flist = self:test_then_block(ls)  -- IF cond THEN block
    while ls.t.token == "TK_ELSEIF" do
        escapelist = luaK:concat(fs, escapelist, luaK:jump(fs))
        luaK:patchtohere(fs, flist)
        flist = self:test_then_block(ls)  -- ELSEIF cond THEN block
    end
    if ls.t.token == "TK_ELSE" then
        escapelist = luaK:concat(fs, escapelist, luaK:jump(fs))
        luaK:patchtohere(fs, flist)
        luaX:next(ls)  -- skip ELSE (after patch, for correct line info)
        self:block(ls)  -- 'else' part
    else
        escapelist = luaK:concat(fs, escapelist, flist)
    end
    luaK:patchtohere(fs, escapelist)
    self:check_match(ls, "TK_END", "TK_IF", line)
end

------------------------------------------------------------------------
-- parse a local function statement
-- * used in statements()
------------------------------------------------------------------------
function luaY:localfunc(ls)
    local v, b = {}, {}  -- expdesc
    local fs = ls.fs
    self:new_localvar(ls, self:str_checkname(ls), 0)
    self:init_exp(v, "VLOCAL", fs.freereg)
    luaK:reserveregs(fs, 1)
    self:adjustlocalvars(ls, 1)
    self:body(ls, b, false, ls.linenumber)
    luaK:storevar(fs, v, b)
    -- debug information will only see the variable after this point!
    self:getlocvar(fs, fs.nactvar - 1).startpc = fs.pc
end

------------------------------------------------------------------------
-- parse a local variable declaration statement
-- * used in statements()
------------------------------------------------------------------------
function luaY:localstat(ls)
    -- stat -> LOCAL NAME {',' NAME} ['=' explist1]
    local nvars = 0
    local nexps
    local e = {}  -- expdesc
    repeat
        self:new_localvar(ls, self:str_checkname(ls), nvars)
        nvars = nvars + 1
    until not self:testnext(ls, ",")
    if self:testnext(ls, "=") then
        nexps = self:explist1(ls, e)
    else
        e.k = "VVOID"
        nexps = 0
    end
    self:adjust_assign(ls, nvars, nexps, e)
    self:adjustlocalvars(ls, nvars)
end

------------------------------------------------------------------------
-- parse a function name specification
-- * used in funcstat()
------------------------------------------------------------------------
function luaY:funcname(ls, v)
    -- funcname -> NAME {field} [':' NAME]
    local needself = false
    self:singlevar(ls, v)
    while ls.t.token == "." do
        self:field(ls, v)
    end
    if ls.t.token == ":" then
        needself = true
        self:field(ls, v)
    end
    return needself
end

------------------------------------------------------------------------
-- parse a function statement
-- * used in statements()
------------------------------------------------------------------------
function luaY:funcstat(ls, line)
    -- funcstat -> FUNCTION funcname body
    local v, b = {}, {}  -- expdesc
    luaX:next(ls)  -- skip FUNCTION
    local needself = self:funcname(ls, v)
    self:body(ls, b, needself, line)
    luaK:storevar(ls.fs, v, b)
    luaK:fixline(ls.fs, line)  -- definition 'happens' in the first line
end

------------------------------------------------------------------------
-- parse a function call with no returns or an assignment statement
-- * used in statements()
------------------------------------------------------------------------
function luaY:exprstat(ls)
    -- stat -> func | assignment
    local fs = ls.fs
    local v = {}  -- LHS_assign
    v.v = {}
    self:primaryexp(ls, v.v)
    if v.v.k == "VCALL" then  -- stat -> func
        luaP:SETARG_C(luaK:getcode(fs, v.v), 1)  -- call statement uses no results
    else  -- stat -> assignment
        v.prev = nil
        self:assignment(ls, v, 1)
    end
end

------------------------------------------------------------------------
-- parse a return statement
-- * used in statements()
------------------------------------------------------------------------
function luaY:retstat(ls)
    -- stat -> RETURN explist
    local fs = ls.fs
    local e = {}  -- expdesc
    local first, nret  -- registers with returned values
    luaX:next(ls)  -- skip RETURN
    if self:block_follow(ls.t.token) or ls.t.token == ";" then
        first, nret = 0, 0  -- return no values
    else
        nret = self:explist1(ls, e)  -- optional return values
        if self:hasmultret(e.k) then
            luaK:setmultret(fs, e)
            if e.k == "VCALL" and nret == 1 then  -- tail call?
                luaP:SET_OPCODE(luaK:getcode(fs, e), "OP_TAILCALL")
                assert(luaP:GETARG_A(luaK:getcode(fs, e)) == fs.nactvar)
            end
            first = fs.nactvar
            nret = self.LUA_MULTRET  -- return all values
        else
            if nret == 1 then  -- only one single value?
                first = luaK:exp2anyreg(fs, e)
            else
                luaK:exp2nextreg(fs, e)  -- values must go to the 'stack'
                first = fs.nactvar  -- return all 'active' values
                assert(nret == fs.freereg - first)
            end
        end--if
    end--if
    luaK:ret(fs, first, nret)
end

------------------------------------------------------------------------
-- initial parsing for statements, calls a lot of functions
-- * returns boolean instead of 0|1
-- * used in chunk()
------------------------------------------------------------------------
function luaY:statement(ls)
    local line = ls.linenumber  -- may be needed for error messages
    local c = ls.t.token
    if c == "TK_IF" then  -- stat -> ifstat
        self:ifstat(ls, line)
        return false
    elseif c == "TK_WHILE" then  -- stat -> whilestat
        self:whilestat(ls, line)
        return false
    elseif c == "TK_DO" then  -- stat -> DO block END
        luaX:next(ls)  -- skip DO
        self:block(ls)
        self:check_match(ls, "TK_END", "TK_DO", line)
        return false
    elseif c == "TK_FOR" then  -- stat -> forstat
        self:forstat(ls, line)
        return false
    elseif c == "TK_REPEAT" then  -- stat -> repeatstat
        self:repeatstat(ls, line)
        return false
    elseif c == "TK_FUNCTION" then  -- stat -> funcstat
        self:funcstat(ls, line)
        return false
    elseif c == "TK_LOCAL" then  -- stat -> localstat
        luaX:next(ls)  -- skip LOCAL
        if self:testnext(ls, "TK_FUNCTION") then  -- local function?
            self:localfunc(ls)
        else
            self:localstat(ls)
        end
        return false
    elseif c == "TK_RETURN" then  -- stat -> retstat
        self:retstat(ls)
        return true  -- must be last statement
    elseif c == "TK_BREAK" then  -- stat -> breakstat
        luaX:next(ls)  -- skip BREAK
        self:breakstat(ls)
        return true  -- must be last statement
    elseif c == "TK_CONTINUE" then  -- stat -> continuestat
        luaX:next(ls)  -- skip CONTINUE
        self:continuestat(ls)
        return true  -- must be last statement
    else
        self:exprstat(ls)
        return false  -- to avoid warnings
    end--if c
end

------------------------------------------------------------------------
-- parse a chunk, which consists of a bunch of statements
-- * used in parser(), body(), block(), repeatstat()
------------------------------------------------------------------------
function luaY:chunk(ls)
    -- chunk -> { stat [';'] }
    local islast = false
    self:enterlevel(ls)
    while not islast and not self:block_follow(ls.t.token) do
        islast = self:statement(ls)
        self:testnext(ls, ";")
        assert(ls.fs.f.maxstacksize >= ls.fs.freereg and
            ls.fs.freereg >= ls.fs.nactvar)
        ls.fs.freereg = ls.fs.nactvar  -- free registers
    end
    self:leavelevel(ls)
end

--# selene: allow(divide_by_zero, multiple_statements, mixed_table)
local bit = bit32
local unpack = table.unpack or unpack

local stm_lua_bytecode
local wrap_lua_func
local stm_lua_func

-- SETLIST config
local FIELDS_PER_FLUSH = 50

-- remap for better lookup
local OPCODE_RM = {
    -- level 1
    [22] = 18, -- JMP
    [31] = 8, -- FORLOOP
    [33] = 28, -- TFORLOOP
    -- level 2
    [0] = 3, -- MOVE
    [1] = 13, -- LOADK
    [2] = 23, -- LOADBOOL
    [26] = 33, -- TEST
    -- level 3
    [12] = 1, -- ADD
    [13] = 6, -- SUB
    [14] = 10, -- MUL
    [15] = 16, -- DIV
    [16] = 20, -- MOD
    [17] = 26, -- POW
    [18] = 30, -- UNM
    [19] = 36, -- NOT
    -- level 4
    [3] = 0, -- LOADNIL
    [4] = 2, -- GETUPVAL
    [5] = 4, -- GETGLOBAL
    [6] = 7, -- GETTABLE
    [7] = 9, -- SETGLOBAL
    [8] = 12, -- SETUPVAL
    [9] = 14, -- SETTABLE
    [10] = 17, -- NEWTABLE
    [20] = 19, -- LEN
    [21] = 22, -- CONCAT
    [23] = 24, -- EQ
    [24] = 27, -- LT
    [25] = 29, -- LE
    [27] = 32, -- TESTSET
    [32] = 34, -- FORPREP
    [34] = 37, -- SETLIST
    -- level 5
    [11] = 5, -- SELF
    [28] = 11, -- CALL
    [29] = 15, -- TAILCALL
    [30] = 21, -- RETURN
    [35] = 25, -- CLOSE
    [36] = 31, -- CLOSURE
    [37] = 35, -- VARARG
}

-- opcode types for getting values
local OPCODE_T = {
    [0] = 'ABC',
    'ABx',
    'ABC',
    'ABC',
    'ABC',
    'ABx',
    'ABC',
    'ABx',
    'ABC',
    'ABC',
    'ABC',
    'ABC',
    'ABC',
    'ABC',
    'ABC',
    'ABC',
    'ABC',
    'ABC',
    'ABC',
    'ABC',
    'ABC',
    'ABC',
    'AsBx',
    'ABC',
    'ABC',
    'ABC',
    'ABC',
    'ABC',
    'ABC',
    'ABC',
    'ABC',
    'AsBx',
    'AsBx',
    'ABC',
    'ABC',
    'ABC',
    'ABx',
    'ABC',
}

local OPCODE_M = {
    [0] = {b = 'OpArgR', c = 'OpArgN'},
    {b = 'OpArgK', c = 'OpArgN'},
    {b = 'OpArgU', c = 'OpArgU'},
    {b = 'OpArgR', c = 'OpArgN'},
    {b = 'OpArgU', c = 'OpArgN'},
    {b = 'OpArgK', c = 'OpArgN'},
    {b = 'OpArgR', c = 'OpArgK'},
    {b = 'OpArgK', c = 'OpArgN'},
    {b = 'OpArgU', c = 'OpArgN'},
    {b = 'OpArgK', c = 'OpArgK'},
    {b = 'OpArgU', c = 'OpArgU'},
    {b = 'OpArgR', c = 'OpArgK'},
    {b = 'OpArgK', c = 'OpArgK'},
    {b = 'OpArgK', c = 'OpArgK'},
    {b = 'OpArgK', c = 'OpArgK'},
    {b = 'OpArgK', c = 'OpArgK'},
    {b = 'OpArgK', c = 'OpArgK'},
    {b = 'OpArgK', c = 'OpArgK'},
    {b = 'OpArgR', c = 'OpArgN'},
    {b = 'OpArgR', c = 'OpArgN'},
    {b = 'OpArgR', c = 'OpArgN'},
    {b = 'OpArgR', c = 'OpArgR'},
    {b = 'OpArgR', c = 'OpArgN'},
    {b = 'OpArgK', c = 'OpArgK'},
    {b = 'OpArgK', c = 'OpArgK'},
    {b = 'OpArgK', c = 'OpArgK'},
    {b = 'OpArgR', c = 'OpArgU'},
    {b = 'OpArgR', c = 'OpArgU'},
    {b = 'OpArgU', c = 'OpArgU'},
    {b = 'OpArgU', c = 'OpArgU'},
    {b = 'OpArgU', c = 'OpArgN'},
    {b = 'OpArgR', c = 'OpArgN'},
    {b = 'OpArgR', c = 'OpArgN'},
    {b = 'OpArgN', c = 'OpArgU'},
    {b = 'OpArgU', c = 'OpArgU'},
    {b = 'OpArgN', c = 'OpArgN'},
    {b = 'OpArgU', c = 'OpArgN'},
    {b = 'OpArgU', c = 'OpArgN'},
}

-- int rd_int_basic(string src, int s, int e, int d)
-- @src - Source binary string
-- @s - Start index of a little endian integer
-- @e - End index of the integer
-- @d - Direction of the loop
local function rd_int_basic(src, s, e, d)
    local num = 0

    -- if bb[l] > 127 then -- signed negative
    -- 	num = num - 256 ^ l
    -- 	bb[l] = bb[l] - 128
    -- end

    for i = s, e, d do num = num + string.byte(src, i, i) * 256 ^ (i - s) end

    return num
end

-- float rd_flt_basic(byte f1..8)
-- @f1..4 - The 4 bytes composing a little endian float
local function rd_flt_basic(f1, f2, f3, f4)
    local sign = (-1) ^ bit.rshift(f4, 7)
    local exp = bit.rshift(f3, 7) + bit.lshift(bit.band(f4, 0x7F), 1)
    local frac = f1 + bit.lshift(f2, 8) + bit.lshift(bit.band(f3, 0x7F), 16)
    local normal = 1

    if exp == 0 then
        if frac == 0 then
            return sign * 0
        else
            normal = 0
            exp = 1
        end
    elseif exp == 0x7F then
        if frac == 0 then
            return sign * (1 / 0)
        else
            return sign * (0 / 0)
        end
    end

    return sign * 2 ^ (exp - 127) * (1 + normal / 2 ^ 23)
end

-- double rd_dbl_basic(byte f1..8)
-- @f1..8 - The 8 bytes composing a little endian double
local function rd_dbl_basic(f1, f2, f3, f4, f5, f6, f7, f8)
    local sign = (-1) ^ bit.rshift(f8, 7)
    local exp = bit.lshift(bit.band(f8, 0x7F), 4) + bit.rshift(f7, 4)
    local frac = bit.band(f7, 0x0F) * 2 ^ 48
    local normal = 1

    frac = frac + (f6 * 2 ^ 40) + (f5 * 2 ^ 32) + (f4 * 2 ^ 24) + (f3 * 2 ^ 16) + (f2 * 2 ^ 8) + f1 -- help

    if exp == 0 then
        if frac == 0 then
            return sign * 0
        else
            normal = 0
            exp = 1
        end
    elseif exp == 0x7FF then
        if frac == 0 then
            return sign * (1 / 0)
        else
            return sign * (0 / 0)
        end
    end

    return sign * 2 ^ (exp - 1023) * (normal + frac / 2 ^ 52)
end

-- int rd_int_le(string src, int s, int e)
-- @src - Source binary string
-- @s - Start index of a little endian integer
-- @e - End index of the integer
local function rd_int_le(src, s, e) return rd_int_basic(src, s, e - 1, 1) end

-- int rd_int_be(string src, int s, int e)
-- @src - Source binary string
-- @s - Start index of a big endian integer
-- @e - End index of the integer
local function rd_int_be(src, s, e) return rd_int_basic(src, e - 1, s, -1) end

-- float rd_flt_le(string src, int s)
-- @src - Source binary string
-- @s - Start index of little endian float
local function rd_flt_le(src, s) return rd_flt_basic(string.byte(src, s, s + 3)) end

-- float rd_flt_be(string src, int s)
-- @src - Source binary string
-- @s - Start index of big endian float
local function rd_flt_be(src, s)
    local f1, f2, f3, f4 = string.byte(src, s, s + 3)
    return rd_flt_basic(f4, f3, f2, f1)
end

-- double rd_dbl_le(string src, int s)
-- @src - Source binary string
-- @s - Start index of little endian double
local function rd_dbl_le(src, s) return rd_dbl_basic(string.byte(src, s, s + 7)) end

-- double rd_dbl_be(string src, int s)
-- @src - Source binary string
-- @s - Start index of big endian double
local function rd_dbl_be(src, s)
    local f1, f2, f3, f4, f5, f6, f7, f8 = string.byte(src, s, s + 7) -- same
    return rd_dbl_basic(f8, f7, f6, f5, f4, f3, f2, f1)
end

-- to avoid nested ifs in deserializing
local float_types = {
    [4] = {little = rd_flt_le, big = rd_flt_be},
    [8] = {little = rd_dbl_le, big = rd_dbl_be},
}

-- byte stm_byte(Stream S)
-- @S - Stream object to read from
local function stm_byte(S)
    local idx = S.index
    local bt = string.byte(S.source, idx, idx)

    S.index = idx + 1
    return bt
end

-- string stm_string(Stream S, int len)
-- @S - Stream object to read from
-- @len - Length of string being read
local function stm_string(S, len)
    local pos = S.index + len
    local str = string.sub(S.source, S.index, pos - 1)

    S.index = pos
    return str
end

-- string stm_lstring(Stream S)
-- @S - Stream object to read from
local function stm_lstring(S)
    local len = S:s_szt()
    local str

    if len ~= 0 then str = string.sub(stm_string(S, len), 1, -2) end

    return str
end

-- fn cst_int_rdr(string src, int len, fn func)
-- @len - Length of type for reader
-- @func - Reader callback
local function cst_int_rdr(len, func)
    return function(S)
        local pos = S.index + len
        local int = func(S.source, S.index, pos)
        S.index = pos

        return int
    end
end

-- fn cst_flt_rdr(string src, int len, fn func)
-- @len - Length of type for reader
-- @func - Reader callback
local function cst_flt_rdr(len, func)
    return function(S)
        local flt = func(S.source, S.index)
        S.index = S.index + len

        return flt
    end
end

local function stm_instructions(S)
    local size = S:s_int()
    local code = {}

    for i = 1, size do
        local ins = S:s_ins()
        local op = bit.band(ins, 0x3F)
        local args = OPCODE_T[op]
        local mode = OPCODE_M[op]
        local data = {value = ins, op = OPCODE_RM[op], A = bit.band(bit.rshift(ins, 6), 0xFF)}

        if args == 'ABC' then
            data.B = bit.band(bit.rshift(ins, 23), 0x1FF)
            data.C = bit.band(bit.rshift(ins, 14), 0x1FF)
            data.is_KB = mode.b == 'OpArgK' and data.B > 0xFF -- post process optimization
            data.is_KC = mode.c == 'OpArgK' and data.C > 0xFF
        elseif args == 'ABx' then
            data.Bx = bit.band(bit.rshift(ins, 14), 0x3FFFF)
            data.is_K = mode.b == 'OpArgK'
        elseif args == 'AsBx' then
            data.sBx = bit.band(bit.rshift(ins, 14), 0x3FFFF) - 131071
        end

        code[i] = data
    end

    return code
end

local function stm_constants(S)
    local size = S:s_int()
    local consts = {}

    for i = 1, size do
        local tt = stm_byte(S)
        local k

        if tt == 1 then
            k = stm_byte(S) ~= 0
        elseif tt == 3 then
            k = S:s_num()
        elseif tt == 4 then
            k = stm_lstring(S)
        end

        consts[i] = k -- offset +1 during instruction decode
    end

    return consts
end

local function stm_subfuncs(S, src)
    local size = S:s_int()
    local sub = {}

    for i = 1, size do
        sub[i] = stm_lua_func(S, src) -- offset +1 in CLOSURE
    end

    return sub
end

local function stm_lineinfo(S)
    local size = S:s_int()
    local lines = {}

    for i = 1, size do lines[i] = S:s_int() end

    return lines
end

local function stm_locvars(S)
    local size = S:s_int()
    local locvars = {}

    for i = 1, size do locvars[i] = {varname = stm_lstring(S), startpc = S:s_int(), endpc = S:s_int()} end

    return locvars
end

local function stm_upvals(S)
    local size = S:s_int()
    local upvals = {}

    for i = 1, size do upvals[i] = stm_lstring(S) end

    return upvals
end

function stm_lua_func(S, psrc)
    local proto = {}
    local src = stm_lstring(S) or psrc -- source is propagated

    proto.source = src -- source name

    S:s_int() -- line defined
    S:s_int() -- last line defined

    proto.numupvals = stm_byte(S) -- num upvalues
    proto.numparams = stm_byte(S) -- num params

    stm_byte(S) -- vararg flag
    stm_byte(S) -- max stack size

    proto.code = stm_instructions(S)
    proto.const = stm_constants(S)
    proto.subs = stm_subfuncs(S, src)
    proto.lines = stm_lineinfo(S)

    stm_locvars(S)
    stm_upvals(S)

    -- post process optimization
    for _, v in ipairs(proto.code) do
        if v.is_K then
            v.const = proto.const[v.Bx + 1] -- offset for 1 based index
        else
            if v.is_KB then v.const_B = proto.const[v.B - 0xFF] end

            if v.is_KC then v.const_C = proto.const[v.C - 0xFF] end
        end
    end

    return proto
end

function stm_lua_bytecode(src)
    -- func reader
    local rdr_func

    -- header flags
    local little
    local size_int
    local size_szt
    local size_ins
    local size_num
    local flag_int

    -- stream object
    local stream = {
        -- data
        index = 1,
        source = src,
    }

    assert(stm_string(stream, 4) == '\27Lua', 'invalid Lua signature')
    assert(stm_byte(stream) == 0x51, 'invalid Lua version')
    assert(stm_byte(stream) == 0, 'invalid Lua format')

    little = stm_byte(stream) ~= 0
    size_int = stm_byte(stream)
    size_szt = stm_byte(stream)
    size_ins = stm_byte(stream)
    size_num = stm_byte(stream)
    flag_int = stm_byte(stream) ~= 0

    rdr_func = little and rd_int_le or rd_int_be
    stream.s_int = cst_int_rdr(size_int, rdr_func)
    stream.s_szt = cst_int_rdr(size_szt, rdr_func)
    stream.s_ins = cst_int_rdr(size_ins, rdr_func)

    if flag_int then
        stream.s_num = cst_int_rdr(size_num, rdr_func)
    elseif float_types[size_num] then
        stream.s_num = cst_flt_rdr(size_num, float_types[size_num][little and 'little' or 'big'])
    else
        error('unsupported float size')
    end

    return stm_lua_func(stream, '@virtual')
end

local function close_lua_upvalues(list, index)
    for i, uv in pairs(list) do
        if uv.index >= index then
            uv.value = uv.store[uv.index] -- store value
            uv.store = uv
            uv.index = 'value' -- self reference
            list[i] = nil
        end
    end
end

local function open_lua_upvalue(list, index, stack)
    local prev = list[index]

    if not prev then
        prev = {index = index, store = stack}
        list[index] = prev
    end

    return prev
end

local function wrap_lua_variadic(...) return select('#', ...), {...} end

local function on_lua_error(exst, err)
    local src = exst.source
    local line = exst.lines[exst.pc - 1]
    local psrc, pline, pmsg = string.match(err or '', '^(.-):(%d+):%s+(.+)')
    local fmt = '%s:%i: [%s:%i] %s'

    line = line or '0'
    psrc = psrc or '?'
    pline = pline or '0'
    pmsg = pmsg or err or ''

    error(string.format(fmt, src, line, psrc, pline, pmsg), 0)
end

local function exec_lua_func(exst)
    -- localize for easy lookup
    local code = exst.code
    local subs = exst.subs
    local env = exst.env
    local upvs = exst.upvals
    local vargs = exst.varargs

    -- state variables
    local stktop = -1
    local openupvs = {}
    local stack = exst.stack
    local pc = exst.pc

    while true do
        local inst = code[pc]
        local op = inst.op
        pc = pc + 1

        if op < 18 then
            if op < 8 then
                if op < 3 then
                    if op < 1 then
                        --[[LOADNIL]]
                        for i = inst.A, inst.B do stack[i] = nil end
                    elseif op > 1 then
                        --[[GETUPVAL]]
                        local uv = upvs[inst.B]

                        stack[inst.A] = uv.store[uv.index]
                    else
                        --[[ADD]]
                        local lhs, rhs

                        if inst.is_KB then
                            lhs = inst.const_B
                        else
                            lhs = stack[inst.B]
                        end

                        if inst.is_KC then
                            rhs = inst.const_C
                        else
                            rhs = stack[inst.C]
                        end

                        stack[inst.A] = lhs + rhs
                    end
                elseif op > 3 then
                    if op < 6 then
                        if op > 4 then
                            --[[SELF]]
                            local A = inst.A
                            local B = inst.B
                            local index

                            if inst.is_KC then
                                index = inst.const_C
                            else
                                index = stack[inst.C]
                            end

                            stack[A + 1] = stack[B]
                            stack[A] = stack[B][index]
                        else
                            --[[GETGLOBAL]]
                            stack[inst.A] = env[inst.const]
                        end
                    elseif op > 6 then
                        --[[GETTABLE]]
                        local index

                        if inst.is_KC then
                            index = inst.const_C
                        else
                            index = stack[inst.C]
                        end

                        stack[inst.A] = stack[inst.B][index]
                    else
                        --[[SUB]]
                        local lhs, rhs

                        if inst.is_KB then
                            lhs = inst.const_B
                        else
                            lhs = stack[inst.B]
                        end

                        if inst.is_KC then
                            rhs = inst.const_C
                        else
                            rhs = stack[inst.C]
                        end

                        stack[inst.A] = lhs - rhs
                    end
                else --[[MOVE]]
                    stack[inst.A] = stack[inst.B]
                end
            elseif op > 8 then
                if op < 13 then
                    if op < 10 then
                        --[[SETGLOBAL]]
                        env[inst.const] = stack[inst.A]
                    elseif op > 10 then
                        if op < 12 then
                            --[[CALL]]
                            local A = inst.A
                            local B = inst.B
                            local C = inst.C
                            local params
                            local sz_vals, l_vals

                            if B == 0 then
                                params = stktop - A
                            else
                                params = B - 1
                            end

                            sz_vals, l_vals = wrap_lua_variadic(stack[A](unpack(stack, A + 1, A + params)))

                            if C == 0 then
                                stktop = A + sz_vals - 1
                            else
                                sz_vals = C - 1
                            end

                            for i = 1, sz_vals do stack[A + i - 1] = l_vals[i] end
                        else
                            --[[SETUPVAL]]
                            local uv = upvs[inst.B]

                            uv.store[uv.index] = stack[inst.A]
                        end
                    else
                        --[[MUL]]
                        local lhs, rhs

                        if inst.is_KB then
                            lhs = inst.const_B
                        else
                            lhs = stack[inst.B]
                        end

                        if inst.is_KC then
                            rhs = inst.const_C
                        else
                            rhs = stack[inst.C]
                        end

                        stack[inst.A] = lhs * rhs
                    end
                elseif op > 13 then
                    if op < 16 then
                        if op > 14 then
                            --[[TAILCALL]]
                            local A = inst.A
                            local B = inst.B
                            local params

                            if B == 0 then
                                params = stktop - A
                            else
                                params = B - 1
                            end

                            close_lua_upvalues(openupvs, 0)
                            return wrap_lua_variadic(stack[A](unpack(stack, A + 1, A + params)))
                        else
                            --[[SETTABLE]]
                            local index, value

                            if inst.is_KB then
                                index = inst.const_B
                            else
                                index = stack[inst.B]
                            end

                            if inst.is_KC then
                                value = inst.const_C
                            else
                                value = stack[inst.C]
                            end

                            stack[inst.A][index] = value
                        end
                    elseif op > 16 then
                        --[[NEWTABLE]]
                        stack[inst.A] = {}
                    else
                        --[[DIV]]
                        local lhs, rhs

                        if inst.is_KB then
                            lhs = inst.const_B
                        else
                            lhs = stack[inst.B]
                        end

                        if inst.is_KC then
                            rhs = inst.const_C
                        else
                            rhs = stack[inst.C]
                        end

                        stack[inst.A] = lhs / rhs
                    end
                else
                    --[[LOADK]]
                    stack[inst.A] = inst.const
                end
            else
                --[[FORLOOP]]
                local A = inst.A
                local step = stack[A + 2]
                local index = stack[A] + step
                local limit = stack[A + 1]
                local loops

                if step == math.abs(step) then
                    loops = index <= limit
                else
                    loops = index >= limit
                end

                if loops then
                    stack[inst.A] = index
                    stack[inst.A + 3] = index
                    pc = pc + inst.sBx
                end
            end
        elseif op > 18 then
            if op < 28 then
                if op < 23 then
                    if op < 20 then
                        --[[LEN]]
                        stack[inst.A] = #stack[inst.B]
                    elseif op > 20 then
                        if op < 22 then
                            --[[RETURN]]
                            local A = inst.A
                            local B = inst.B
                            local vals = {}
                            local size

                            if B == 0 then
                                size = stktop - A + 1
                            else
                                size = B - 1
                            end

                            for i = 1, size do vals[i] = stack[A + i - 1] end

                            close_lua_upvalues(openupvs, 0)
                            return size, vals
                        else
                            --[[CONCAT]]
                            local str = stack[inst.B]

                            for i = inst.B + 1, inst.C do str = str .. stack[i] end

                            stack[inst.A] = str
                        end
                    else
                        --[[MOD]]
                        local lhs, rhs

                        if inst.is_KB then
                            lhs = inst.const_B
                        else
                            lhs = stack[inst.B]
                        end

                        if inst.is_KC then
                            rhs = inst.const_C
                        else
                            rhs = stack[inst.C]
                        end

                        stack[inst.A] = lhs % rhs
                    end
                elseif op > 23 then
                    if op < 26 then
                        if op > 24 then
                            --[[CLOSE]]
                            close_lua_upvalues(openupvs, inst.A)
                        else
                            --[[EQ]]
                            local lhs, rhs

                            if inst.is_KB then
                                lhs = inst.const_B
                            else
                                lhs = stack[inst.B]
                            end

                            if inst.is_KC then
                                rhs = inst.const_C
                            else
                                rhs = stack[inst.C]
                            end

                            if (lhs == rhs) == (inst.A ~= 0) then pc = pc + code[pc].sBx end

                            pc = pc + 1
                        end
                    elseif op > 26 then
                        --[[LT]]
                        local lhs, rhs

                        if inst.is_KB then
                            lhs = inst.const_B
                        else
                            lhs = stack[inst.B]
                        end

                        if inst.is_KC then
                            rhs = inst.const_C
                        else
                            rhs = stack[inst.C]
                        end

                        if (lhs < rhs) == (inst.A ~= 0) then pc = pc + code[pc].sBx end

                        pc = pc + 1
                    else
                        --[[POW]]
                        local lhs, rhs

                        if inst.is_KB then
                            lhs = inst.const_B
                        else
                            lhs = stack[inst.B]
                        end

                        if inst.is_KC then
                            rhs = inst.const_C
                        else
                            rhs = stack[inst.C]
                        end

                        stack[inst.A] = lhs ^ rhs
                    end
                else
                    --[[LOADBOOL]]
                    stack[inst.A] = inst.B ~= 0

                    if inst.C ~= 0 then pc = pc + 1 end
                end
            elseif op > 28 then
                if op < 33 then
                    if op < 30 then
                        --[[LE]]
                        local lhs, rhs

                        if inst.is_KB then
                            lhs = inst.const_B
                        else
                            lhs = stack[inst.B]
                        end

                        if inst.is_KC then
                            rhs = inst.const_C
                        else
                            rhs = stack[inst.C]
                        end

                        if (lhs <= rhs) == (inst.A ~= 0) then pc = pc + code[pc].sBx end

                        pc = pc + 1
                    elseif op > 30 then
                        if op < 32 then
                            --[[CLOSURE]]
                            local sub = subs[inst.Bx + 1] -- offset for 1 based index
                            local nups = sub.numupvals
                            local uvlist

                            if nups ~= 0 then
                                uvlist = {}

                                for i = 1, nups do
                                    local pseudo = code[pc + i - 1]

                                    if pseudo.op == OPCODE_RM[0] then -- @MOVE
                                        uvlist[i - 1] = open_lua_upvalue(openupvs, pseudo.B, stack)
                                    elseif pseudo.op == OPCODE_RM[4] then -- @GETUPVAL
                                        uvlist[i - 1] = upvs[pseudo.B]
                                    end
                                end

                                pc = pc + nups
                            end

                            stack[inst.A] = wrap_lua_func(sub, env, uvlist)
                        else
                            --[[TESTSET]]
                            local A = inst.A
                            local B = inst.B

                            if (not stack[B]) == (inst.C ~= 0) then
                                pc = pc + 1
                            else
                                stack[A] = stack[B]
                            end
                        end
                    else
                        --[[UNM]]
                        stack[inst.A] = -stack[inst.B]
                    end
                elseif op > 33 then
                    if op < 36 then
                        if op > 34 then
                            --[[VARARG]]
                            local A = inst.A
                            local size = inst.B

                            if size == 0 then
                                size = vargs.size
                                stktop = A + size - 1
                            end

                            for i = 1, size do stack[A + i - 1] = vargs.list[i] end
                        else
                            --[[FORPREP]]
                            local A = inst.A
                            local init, limit, step

                            init = assert(tonumber(stack[A]), '`for` initial value must be a number')
                            limit = assert(tonumber(stack[A + 1]), '`for` limit must be a number')
                            step = assert(tonumber(stack[A + 2]), '`for` step must be a number')

                            stack[A] = init - step
                            stack[A + 1] = limit
                            stack[A + 2] = step

                            pc = pc + inst.sBx
                        end
                    elseif op > 36 then
                        --[[SETLIST]]
                        local A = inst.A
                        local C = inst.C
                        local size = inst.B
                        local tab = stack[A]
                        local offset

                        if size == 0 then size = stktop - A end

                        if C == 0 then
                            C = inst[pc].value
                            pc = pc + 1
                        end

                        offset = (C - 1) * FIELDS_PER_FLUSH

                        for i = 1, size do tab[i + offset] = stack[A + i] end
                    else
                        --[[NOT]]
                        stack[inst.A] = not stack[inst.B]
                    end
                else
                    --[[TEST]]
                    if (not stack[inst.A]) == (inst.C ~= 0) then pc = pc + 1 end
                end
            else
                --[[TFORLOOP]]
                local A = inst.A
                local func = stack[A]
                local state = stack[A + 1]
                local index = stack[A + 2]
                local base = A + 3
                local vals

                -- === Luau compatibility - General iteration begin ===
                -- // ccuser44 added support for generic iteration
                -- (Please don't use general iteration in vanilla Lua code)
                if not index and not state and type(func) == "table" then
                    -- Hacky check to see if __metatable is locked
                    local canGetMt = pcall(getmetatable, func)
                    local isMtLocked = canGetMt and not pcall(setmetatable, func, getmetatable(func)) or not canGetMt
                    local metatable = canGetMt and getmetatable(func)

                    if not (table.isfrozen and table.isfrozen(func)) and isMtLocked and not metatable then
                        warn("The table has a metatable buts it's hidden, __iter and __call won't work in forloop.")
                    end

                    if not (type(metatable) == "table" and rawget(metatable, "__call")) then
                        func, state, index = (type(metatable) == "table" and rawget(metatable, "__iter") or next), func, nil
                        stack[A], stack[A + 1], stack[A + 2] = func, state, index
                    end
                end
                -- === Luau compatibility - General iteration end ===

                stack[base + 2] = index
                stack[base + 1] = state
                stack[base] = func

                vals = {func(state, index)}

                for i = 1, inst.C do stack[base + i - 1] = vals[i] end

                if stack[base] ~= nil then
                    stack[A + 2] = stack[base]
                else
                    pc = pc + 1
                end
            end
        else
            --[[JMP]]
            pc = pc + inst.sBx
        end

        exst.pc = pc
    end
end

function wrap_lua_func(state, env, upvals)
    local st_code = state.code
    local st_subs = state.subs
    local st_lines = state.lines
    local st_source = state.source
    local st_numparams = state.numparams

    local function exec_wrap(...)
        local stack = {}
        local varargs = {}
        local sizevarg = 0
        local sz_args, l_args = wrap_lua_variadic(...)

        local exst
        local ok, err, vals

        for i = 1, st_numparams do stack[i - 1] = l_args[i] end

        if st_numparams < sz_args then
            sizevarg = sz_args - st_numparams
            for i = 1, sizevarg do varargs[i] = l_args[st_numparams + i] end
        end

        exst = {
            varargs = {list = varargs, size = sizevarg},
            code = st_code,
            subs = st_subs,
            lines = st_lines,
            source = st_source,
            env = env,
            upvals = upvals,
            stack = stack,
            pc = 1,
        }

        ok, err, vals = pcall(exec_lua_func, exst, ...)

        if ok then
            return unpack(vals, 1, err)
        else
            on_lua_error(exst, err)
        end

        return -- explicit "return nothing"
    end

    return exec_wrap
end

local function load_lua_func(BCode, Env)
    return wrap_lua_func(stm_lua_bytecode(BCode), Env or {})
end


--? Initialization

luaX:init()
local LuaState = {}

local function ExecuteCode(str, env)
    if not getfenv().NanocoreVM then
        getfenv().NanocoreVM = true
    end
    local f, writer, buff
    env = env or getfenv(2)
    local ran = xpcall(function()
        local zio = luaZ:init(luaZ:make_getS(str), nil)
        local func = luaY:parser(LuaState, zio, nil, "NanocoreVM")
        writer, buff = luaU:make_setS()
        luaU:dump(LuaState, func, writer, buff)
        f = load_lua_func(buff.data, env)
    end, function(err)
        return warn(err)
    end)
    if ran then
        return f, buff.data
    end
end


--? Configuration

task.spawn(AutoRename, Executor)
xpcall(function()
    Executor.Parent = CoreGui:WaitForChild("RobloxGui", math.huge)
end, function()
    local Nanocore = Instance.new("ScreenGui")
    task.spawn(AutoRename, Nanocore)
    Nanocore.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    Nanocore.DisplayOrder = 9e8
    Nanocore.IgnoreGuiInset = true
    Nanocore.Parent = Player:WaitForChild("PlayerGui", math.huge)
    Executor.Parent = Nanocore
end)

Executor.AnchorPoint = Vector2.new(0.5, 0.5)
Executor.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
Executor.BorderSizePixel = 0
Executor.Position = UDim2.new(0.5, 0, 0.5, 0)
Executor.Size = UDim2.new(0, 500, 0, 300)

task.spawn(AutoRename, UICorner)
UICorner.CornerRadius = UDim.new(0, 4)
UICorner.Parent = Executor

task.spawn(AutoRename, Title)
Title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
Title.BorderSizePixel = 0
Title.Size = UDim2.new(1, 0, 0, 30)
Title.ZIndex = 2
Title.Font = Enum.Font.Gotham
Title.Text = "Nanocore"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 14
Title.Parent = Executor

task.spawn(AutoRename, UICorner_2)
UICorner_2.CornerRadius = UDim.new(0, 4)
UICorner_2.Parent = Title

task.spawn(AutoRename, Editor)
Editor.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
Editor.BorderSizePixel = 0
Editor.ClipsDescendants = true
Editor.Position = UDim2.new(0, 10, 0, 40)
Editor.Size = UDim2.new(1, -20, 1, -90)
Editor.Parent = Executor

task.spawn(AutoRename, Code)
Code.Active = true
Code.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Code.BackgroundTransparency = 1
Code.BorderSizePixel = 0
Code.Size = UDim2.new(1.04583335, -22, 1, 0)
Code.AutomaticCanvasSize = Enum.AutomaticSize.XY
Code.CanvasSize = UDim2.new(0, 0, 0, 0)
Code.ScrollBarThickness = 6
Code.Parent = Editor

task.spawn(AutoRename, Content)
Content.AutomaticSize = Enum.AutomaticSize.XY
Content.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.Size = UDim2.new(1, 0, 1, 0)
Content.ClearTextOnFocus = false
Content.Font = Enum.Font.Code
Content.MultiLine = true
Content.Text = "print(\"Hello world!\")"
Content.TextColor3 = Color3.fromRGB(255, 255, 255)
Content.TextSize = 14
Content.TextXAlignment = Enum.TextXAlignment.Left
Content.TextYAlignment = Enum.TextYAlignment.Top
Content.Parent = Code

task.spawn(AutoRename, UIPadding)
UIPadding.PaddingLeft = UDim.new(0, 8)
UIPadding.PaddingTop = UDim.new(0, 5)
UIPadding.Parent = Content

task.spawn(AutoRename, Buttons)
Buttons.AnchorPoint = Vector2.new(0, 1)
Buttons.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Buttons.BackgroundTransparency = 1
Buttons.BorderSizePixel = 0
Buttons.Position = UDim2.new(0, 10, 1, -10)
Buttons.Size = UDim2.new(1, -20, 0, 30)
Buttons.Parent = Executor

task.spawn(AutoRename, UIListLayout)
UIListLayout.FillDirection = Enum.FillDirection.Horizontal
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 10)
UIListLayout.Parent = Buttons

task.spawn(AutoRename, Execute)
Execute.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
Execute.BorderSizePixel = 0
Execute.LayoutOrder = 1
Execute.Size = UDim2.new(0, 80, 1, 0)
Execute.AutoButtonColor = false
Execute.Font = Enum.Font.Gotham
Execute.Text = "Execute"
Execute.TextColor3 = Color3.fromRGB(255, 255, 255)
Execute.TextSize = 14
Execute.Parent = Buttons

task.spawn(AutoRename, UIStroke)
UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStroke.Color = Color3.fromRGB(150, 150, 150)
UIStroke.Transparency = 1
UIStroke.Parent = Execute

task.spawn(AutoRename, UICorner_3)
UICorner_3.CornerRadius = UDim.new(0, 4)
UICorner_3.Parent = Execute

task.spawn(AutoRename, Clear)
Clear.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
Clear.BorderSizePixel = 0
Clear.LayoutOrder = 2
Clear.Size = UDim2.new(0, 80, 1, 0)
Clear.AutoButtonColor = false
Clear.Font = Enum.Font.Gotham
Clear.Text = "Clear"
Clear.TextColor3 = Color3.fromRGB(255, 255, 255)
Clear.TextSize = 14
Clear.Parent = Buttons

task.spawn(AutoRename, UIStroke_2)
UIStroke_2.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
UIStroke_2.Color = Color3.fromRGB(150, 150, 150)
UIStroke_2.Transparency = 1
UIStroke_2.Parent = Clear

task.spawn(AutoRename, UICorner_4)
UICorner_4.CornerRadius = UDim.new(0, 4)
UICorner_4.Parent = Clear

task.spawn(AutoRename, UIStroke_3)
UIStroke_3.Color = Color3.fromRGB(120, 120, 120)
UIStroke_3.Parent = Executor

task.spawn(SmoothDrag, Executor)


--? Logic

local Token = string.upper(RandomString())
local EQ = false

pcall(function()
    getfenv().loadstring(string.format("getfenv()[\"%s\"] = 0", Token))()
    if getfenv()[Token] == 0 then
        EQ = true
        getfenv()[Token] = nil
    end
end)

if not EQ then
    getfenv().loadstring = ExecuteCode
end

Token = nil
EQ = false

local Activated = {
    Execute = function()
        xpcall(function()
            getfenv().loadstring(Content.Text)()
        end, function(Error)
            if getfenv().NanocoreVM and string.find(Error, "NanocoreVM") or not getfenv().NanocoreVM then
                warn(Error)
            end
        end)
    end,
    Clear = function()
        Content.Text = ""
    end
}

for _, Button in next, Buttons:GetChildren() do
    if Button:IsA("TextButton") then
        Button.AutoButtonColor = false
        local Stroke = Button:FindFirstChildWhichIsA("UIStroke")
        Button.MouseEnter:Connect(function()
            Stroke.Transparency = 1
            Stroke.Color = ButtonHover
            Tween(Stroke, StrokeTweenInfo, {Transparency = 0})
        end)
        Button.MouseLeave:Connect(function()
            Tween(Stroke, StrokeTweenInfo, {Transparency = 1})
        end)
        Button.MouseButton1Down:Connect(function()
            Tween(Stroke, StrokeTweenInfo, {Color = ButtonDown})
        end)
        Button.MouseButton1Up:Connect(function()
            Tween(Stroke, StrokeTweenInfo, {Color = ButtonHover})
        end)
        Button.Activated:Connect(Activated[Button.Text])
    end
end