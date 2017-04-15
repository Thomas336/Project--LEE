AddCSLuaFile()
DEFINE_BASECLASS( "base_wire_entity" )
ENT.PrintName       = "Wire Lua Gate"
ENT.Author          = "Thomas"
ENT.WireDebugName	= "LuaGate"

if CLIENT then return end -- No more client

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)

	self.Inputs = Wire_CreateInputs(self, { "MemBus", "IOBus", "Frequency", "Clk", "Reset", "Interrupt"})
	self.Outputs = Wire_CreateOutputs(self, { "Error" })

	-- CPU platform settings
	--self.Clk = false -- whether the Clk input is on
	--self.VMStopped = false -- whether the VM has halted itself (e.g. by running off the end of the program)
	--self.Frequency = 2000

	-- Create virtual machine
	--self.VM = CPULib.VirtualMachine()
	--self.VM.SerialNo = CPULib.GenerateSN("CPU")
	--self.VM:Reset()

	self:SetName()
	--[[self:SetMemoryModel("64krom")
	self.VM.SignalError = function(VM,errorCode)
		Wire_TriggerOutput(self, "Error", errorCode)
	end
	self.VM.SignalShutdown = function(VM)
		self.VMStopped = true
	end
	self.VM.ExternalWrite = function(VM,Address,Value)
		if Address >= 0 then -- Use MemBus
			local MemBusSource = self.Inputs.MemBus.Src
			if MemBusSource then
				if MemBusSource.ReadCell then
					local result = MemBusSource:WriteCell(Address-self.VM.RAMSize,Value)
					if result then return true
					else VM:Interrupt(7,Address) return false
					end
				else VM:Interrupt(8,Address) return false
				end
			else VM:Interrupt(7,Address) return false
			end
		else -- Use IOBus
			local IOBusSource = self.Inputs.IOBus.Src
			if IOBusSource then
				if IOBusSource.ReadCell then
					local result = IOBusSource:WriteCell(-Address-1,Value)
					if result then return true
					else VM:Interrupt(10,-Address-1) return false
					end
				else VM:Interrupt(8,Address+1) return false
				end
			else return true
			end
		end
	end
	self.VM.ExternalRead = function(VM,Address)
		if Address >= 0 then -- Use MemBus
			local MemBusSource = self.Inputs.MemBus.Src
			if MemBusSource then
				if MemBusSource.ReadCell then
					local result = MemBusSource:ReadCell(Address-self.VM.RAMSize)
					if result then return result
					else VM:Interrupt(7,Address) return
					end
				else VM:Interrupt(8,Address) return
				end
			else VM:Interrupt(7,Address) return
			end
		else -- Use IOBus
			local IOBusSource = self.Inputs.IOBus.Src
			if IOBusSource then
				if IOBusSource.ReadCell then
					local result = IOBusSource:ReadCell(-Address-1)
					if result then return result
					else VM:Interrupt(10,-Address-1) return
					end
				else VM:Interrupt(8,Address+1) return
				end
			else return 0 
			end
		end
	end
	
	local oldReset = self.VM.Reset
	self.VM.Reset = function(...)
		if self.Clk and self.VMStopped then
			self:NextThink(CurTime())
		end
		self.VMStopped = false
		return oldReset(...)
	end]]--

	-- Player that debugs the processor
	self.DebuggerPlayer = nil
end

-- Execute ZCPU virtual machine
function ENT:Run()
	-- Do not run if debugging is active
	if self.DebuggerPlayer then return end

	-- Calculate time-related variables
	local CurrentTime = CurTime()
	local DeltaTime = math.min(1/30,CurrentTime - (self.PreviousTime or 0))
	self.PreviousTime = CurrentTime
	
	coroutine.resume(self.tScript)
	-- Check if need to run till specific instruction
	--[[if self.BreakpointInstructions then
		self.VM.TimerDT = DeltaTime	
		self.VM.CPUIF = self
		self.VM:Step(8,function(self)
			-- self:Emit("VM.IP = "..(self.PrecompileIP or 0))
			-- self:Emit("VM.XEIP = "..(self.PrecompileTrueXEIP or 0))

			self:Dyn_Emit("if (VM.CPUIF.Clk and not VM.CPUIF.VMStopped) and (VM.CPUIF.OnVMStep) then")
				self:Dyn_EmitState()
				self:Emit("VM.CPUIF.OnVMStep()")
			self:Emit("end")
			self:Emit("if VM.CPUIF.BreakpointInstructions[VM.IP] then")
				self:Dyn_EmitState()
				self:Emit("VM.CPUIF.OnBreakpointInstruction(VM.IP)")
				self:Emit("VM.CPUIF.VMStopped = true")
				self:Emit("VM.TMR = VM.TMR + "..self.PrecompileInstruction)
				self:Emit("VM.CODEBYTES = VM.CODEBYTES + "..self.PrecompileBytes)
				self:Emit("if true then return end")
			self:Emit("end")
			self:Emit("if VM.CPUIF.LastInstruction and ((VM.IP > VM.CPUIF.LastInstruction) or VM.CPUIF.ForceLastInstruction) then")
				self:Dyn_EmitState()
				self:Emit("VM.CPUIF.ForceLastInstruction = nil")
				self:Emit("VM.CPUIF.OnLastInstruction()")
				self:Emit("VM.CPUIF.VMStopped = true")
				self:Emit("VM.TMR = VM.TMR + "..self.PrecompileInstruction)
				self:Emit("VM.CODEBYTES = VM.CODEBYTES + "..self.PrecompileBytes)
				self:Emit("if true then return end")
			self:Emit("end")
		end)
		self.VM.CPUIF = nil
	else
		-- How many steps VM must make to keep up with execution
		local Cycles = math.max(1,math.floor(self.Frequency*DeltaTime*0.5))
		self.VM.TimerDT = (DeltaTime/Cycles)

		while (Cycles > 0) and (self.Clk) and (not self.VMStopped) and (self.VM.Idle == 0) do
			-- Run VM step
			local previousTMR = self.VM.TMR
			self.VM:Step()
			Cycles = Cycles - math.max(1, self.VM.TMR - previousTMR)
		end
	end

	-- Update VM timer
	self.VM.TIMER = self.VM.TIMER + DeltaTime

	-- Reset idle register
	self.VM.Idle = 0]]--
end

function ENT:Think()
	if self.script then
		self:Run()         --self.VMStopped
	end
	if self.Clk and not false then self:NextThink(CurTime()) end
	return true
end

function ENT:LoadCode(code, filepath, owner)
	self.script = code
	self.MyName = filepath
	self.owner = owner
	
	self:CompileCode(code)
end

function ENT:GetCode()
	return self.script
end

function ENT:CompileCode(code)
	local tEnv = {}
	local fnScript = CompileString(self.script, "Lua gate", false)
	if type(fnScript) == "string" then
		WireLib.AddNotify(self.owner, "Compile error: "..fnScript, NOTIFY_ERROR, 7, NOTIFYSOUND_DRIP3)
	elseif type(fnScript) == "function" then
		setmetatable(tEnv, {__index = _G})
		setfenv(fnScript, tEnv)
		self.tScript = coroutine.create(fnScript)
	end
end

function ENT:SetName(name)
	local overlayStr = ""
	if name and (name ~= "") then
		self:SetOverlayText(string.format("%s"))
	else
		self:SetOverlayText(string.format("Lua Gate"))
	end
	self.MyName = name
end

function ENT:BuildDupeInfo()
	local info = self.BaseClass.BuildDupeInfo(self) or {}

	--info.SerialNo = self.VM.SerialNo
	--info.InternalRAMSize = self.VM.RAMSize
	--info.InternalROMSize = self.VM.ROMSize
	--info.MyName         = self.MyName

	--if self.VM.ROMSize > 0 then
	--	info.Memory = {}
	--	for k,v in pairs(self.VM.ROM) do if v ~= 0 then info.Memory[k] = v end end
	--end

	return info
end

function ENT:ApplyDupeInfo(ply, ent, info, GetEntByID)
	--self.BaseClass.ApplyDupeInfo(self, ply, ent, info, GetEntByID)

	--self.VM.SerialNo = info.SerialNo or CPULib.GenerateSN("UNK")
	--self.VM.RAMSize  = info.InternalRAMSize or 65536
	--self.VM.ROMSize  = info.InternalROMSize or 65536
	--self:SetName(info.MyName)

	--if info.Memory then--and
		 --(((info.UseROM) and (info.UseROM == true)) or
		 -- ((info.InternalROMSize) and (info.InternalROMSize > 0))) then
	--	self.VM.ROM = {}
	--	for k,v in pairs(info.Memory) do self.VM.ROM[k] = tonumber(v) or 0 end
	--	self.VM:Reset()
	--end
end

-- Compatibility with old NMI input
--WireLib.AddInputAlias( "NMI", "Interrupt" )

--[[function ENT:TriggerInput(iname, value)
	if iname == "Clk" then
		self.Clk = (value >= 1)
		if self.Clk then
			self.VMStopped = false
			self:NextThink(CurTime())
		end
	elseif iname == "Frequency" then
		if (not game.SinglePlayer()) and (value > 1400000) then self.Frequency = 1400000 return end
		if value > 0 then self.Frequency = math.floor(value) end
	elseif iname == "Reset" then   --VM may be nil
		if self.VM.HWDEBUG ~= 0 then
			self.VM.DBGSTATE = math.floor(value)
			if (value > 0) and (value <= 1.0) then self.VM:Reset() end
		else
			if value >= 1.0 then self.VM:Reset() end
		end
		Wire_TriggerOutput(self, "Error", 0)
	elseif iname == "Interrupt" then
		if (value >= 32) && (value < 256) then
			if (self.Clk and not self.VMStopped) then self.VM:ExternalInterrupt(math.floor(value)) end
		end
	end
end]]--

duplicator.RegisterEntityClass("gmod_wire_luagate", WireLib.MakeWireEnt, "Data")
