-- =================================================================
-- INDO KOS - FULL AUTO FARM & PLAYER UTILITY GUI (1 SCRIPT STANDALONE)
-- VERSI STRICT GARBAGE ISOLATION: GARBAGE TAKE & DISCARD KHUSUS AREA BOS
-- =================================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- Global Configuration & State
local Config = {
	AutoClean = false,
	WalkSpeed = 16,
	JumpPower = 50,
	FlyEnabled = false,
	FlySpeed = 50
}

-- Blacklist Memory untuk Prompt & Model yang "Bukan Zona Kerjamu"
local BlacklistedPrompts = {}
local BlacklistedModels = {}
local LastAttemptedPrompt = nil

-- References GUI
local ScreenGui = nil
local AutoCleanToggleBtn = nil

-- Helper Notifikasi UI
local function notify(title, message, duration)
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = title or "Auto Clean Indo Kos",
			Text = message or "",
			Duration = duration or 5
		})
	end)
end

-- Destroy GUI lama jika ada
local existingGui = CoreGui:FindFirstChild("IndoKosUtilityGui") or LocalPlayer.PlayerGui:FindFirstChild("IndoKosUtilityGui")
if existingGui then existingGui:Destroy() end

-- =================================================================
-- 1. REALTIME WARNING LISTENER ("Bukan Zona Kerjamu")
-- =================================================================

local function isBlacklisted(prompt)
	if not prompt or not prompt.Parent then return true end
	if BlacklistedPrompts[prompt] then return true end

	local current = prompt.Parent
	while current and current ~= Workspace do
		if BlacklistedModels[current] then
			return true
		end
		current = current.Parent
	end

	return false
end

local function isModelBlacklisted(model)
	if not model then return true end
	local current = model
	while current and current ~= Workspace do
		if BlacklistedModels[current] then return true end
		current = current.Parent
	end
	return false
end

local function blacklistLastPrompt()
	if LastAttemptedPrompt then
		BlacklistedPrompts[LastAttemptedPrompt] = true
		local parentModel = LastAttemptedPrompt:FindFirstAncestorWhichIsA("Model") or LastAttemptedPrompt:FindFirstAncestorWhichIsA("Folder") or LastAttemptedPrompt.Parent
		if parentModel then
			BlacklistedModels[parentModel] = true
		end
		print("[AutoClean] Blacklisted Non-Boss Prompt/Model: " .. tostring(LastAttemptedPrompt.Name))
	end
end

local function checkGameWarnings()
	local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
	if not playerGui then return end

	for _, descendant in ipairs(playerGui:GetDescendants()) do
		if descendant:IsA("TextLabel") and descendant.Visible then
			local text = string.lower(descendant.Text or "")
			if string.find(text, "bukan zona kerjamu") or string.find(text, "zona bosmu") or string.find(text, "bukan zona") then
				blacklistLastPrompt()
				break
			end
		end
	end
end

-- =================================================================
-- 2. DETEKTOR OTOMATIS STATUS PETUGAS KEBERSIHAN & MODEL AREA BOS
-- =================================================================

local function isPlayerEmployee()
	local isEmployee = false
	local character = LocalPlayer.Character

	if character then
		for _, desc in ipairs(character:GetDescendants()) do
			if desc:IsA("TextLabel") and desc.Visible then
				local txt = string.lower(desc.Text or "")
				if string.find(txt, "employee") or string.find(txt, "petugas") or string.find(txt, "pembersih") or string.find(txt, "cleaner") then
					isEmployee = true
					break
				end
			end
		end
	end

	if not isEmployee then
		local playerAttributes = LocalPlayer:GetAttributes()
		for attrName, attrVal in pairs(playerAttributes) do
			local lowerName = string.lower(attrName)
			local lowerVal = type(attrVal) == "string" and string.lower(attrVal) or ""
			if string.find(lowerName, "job") or string.find(lowerName, "employee") or string.find(lowerVal, "employee") or string.find(lowerVal, "bersih") then
				isEmployee = true
				break
			end
		end
	end

	if not isEmployee then
		for _, prompt in ipairs(Workspace:GetDescendants()) do
			if prompt:IsA("ProximityPrompt") and prompt.Enabled and not isBlacklisted(prompt) then
				local action = string.lower(prompt.ActionText or "")
				local objText = string.lower(prompt.ObjectText or "")
				if (string.find(action, "clean") or string.find(action, "take") or string.find(action, "bersih")) 
					and (string.find(objText, "dirt") or string.find(objText, "garbage") or string.find(objText, "kotor")) then
					isEmployee = true
					break
				end
			end
		end
	end

	return isEmployee
end

-- Mendapatkan Model Area Kerja Bos Aktif (Strict Boss Model)
local function getBossAreaModel()
	local character = LocalPlayer.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	local closestDist = math.huge
	local bossModel = nil

	-- 1. Cari Billboard TextLabel "KOTOR" atau "DIRTY"
	for _, desc in ipairs(Workspace:GetDescendants()) do
		if desc:IsA("TextLabel") and desc.Visible then
			local txt = string.upper(desc.Text or "")
			if string.find(txt, "KOTOR") or string.find(txt, "DIRTY") then
				local modelAncestor = desc:FindFirstAncestorWhichIsA("Model") or desc:FindFirstAncestorWhichIsA("Folder")
				if modelAncestor and not isModelBlacklisted(modelAncestor) and rootPart then
					local pos = modelAncestor:GetPivot().Position
					local dist = (rootPart.Position - pos).Magnitude
					if dist < closestDist then
						closestDist = dist
						bossModel = modelAncestor
					end
				end
			end
		end
	end

	-- 2. Jika tidak ada billboard, cari dari Dirt Clean prompt terdekat yang valid
	if not bossModel then
		for _, prompt in ipairs(Workspace:GetDescendants()) do
			if prompt:IsA("ProximityPrompt") and prompt.Enabled and not isBlacklisted(prompt) then
				local action = string.lower(prompt.ActionText or "")
				local objText = string.lower(prompt.ObjectText or "")
				if string.find(objText, "dirt") or string.find(action, "clean") or string.find(objText, "kotor") then
					local modelAncestor = prompt:FindFirstAncestorWhichIsA("Model") or prompt:FindFirstAncestorWhichIsA("Folder")
					if modelAncestor and not isModelBlacklisted(modelAncestor) and rootPart then
						local pos = modelAncestor:GetPivot().Position
						local dist = (rootPart.Position - pos).Magnitude
						if dist < closestDist then
							closestDist = dist
							bossModel = modelAncestor
						end
					end
				end
			end
		end
	end

	return bossModel
end

-- =================================================================
-- 3. DETEKTOR PROMPT STRICT BOSS ZONE (DIRT, GARBAGE TAKE & DISCARD)
-- =================================================================

-- 1. Deteksi "Dirt Clean" di Zona Bos
local function getValidDirtCleanPrompts(bossModel)
	local prompts = {}
	local searchScope = bossModel or Workspace
	local character = LocalPlayer.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")

	for _, descendant in ipairs(searchScope:GetDescendants()) do
		if descendant:IsA("ProximityPrompt") and descendant.Enabled and not isBlacklisted(descendant) then
			local action = string.lower(descendant.ActionText or "")
			local objText = string.lower(descendant.ObjectText or "")
			if (string.find(objText, "dirt") or string.find(action, "clean") or string.find(objText, "kotor")) then
				table.insert(prompts, descendant)
			end
		end
	end

	if rootPart then
		table.sort(prompts, function(a, b)
			local posA = a.Parent:IsA("BasePart") and a.Parent.Position or a.Parent:GetPivot().Position
			local posB = b.Parent:IsA("BasePart") and b.Parent.Position or b.Parent:GetPivot().Position
			return (rootPart.Position - posA).Magnitude < (rootPart.Position - posB).Magnitude
		end)
	end

	return prompts
end

-- 2. Deteksi "Garbage Take" KHUSUS HANYA DI DALAM AREA BOS (Strict Isolation)
local function getValidGarbageTakePrompts(bossModel)
	local prompts = {}
	local searchScope = bossModel or Workspace
	local character = LocalPlayer.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")

	for _, descendant in ipairs(searchScope:GetDescendants()) do
		if descendant:IsA("ProximityPrompt") and descendant.Enabled and not isBlacklisted(descendant) then
			local action = string.lower(descendant.ActionText or "")
			local objText = string.lower(descendant.ObjectText or "")
			local name = string.lower(descendant.Name or "")
			local parentName = descendant.Parent and string.lower(descendant.Parent.Name) or ""

			local isGarbageTake = false
			if (string.find(action, "take") and string.find(objText, "garbage"))
				or (string.find(objText, "garbage") and not string.find(objText, "bin"))
				or (string.find(action, "take") and string.find(objText, "sampah"))
				or string.find(name, "garbage") or string.find(name, "trash") or string.find(name, "sampah")
				or string.find(parentName, "garbage") or string.find(parentName, "trash") or string.find(parentName, "sampah") then
				
				if not string.find(objText, "bin") and not string.find(action, "discard") and not string.find(name, "bin") then
					isGarbageTake = true
				end
			end

			if isGarbageTake then
				table.insert(prompts, descendant)
			end
		end
	end

	if rootPart then
		table.sort(prompts, function(a, b)
			local posA = a.Parent:IsA("BasePart") and a.Parent.Position or a.Parent:GetPivot().Position
			local posB = b.Parent:IsA("BasePart") and b.Parent.Position or b.Parent:GetPivot().Position
			return (rootPart.Position - posA).Magnitude < (rootPart.Position - posB).Magnitude
		end)
	end

	return prompts
end

-- 3. Deteksi Tempat Sampah "Garbage Bin Discard" (Prioritas Dalam Area Bos / Bak Terdekat Valid)
local function getValidGarbageBinPrompts(bossModel)
	local prompts = {}
	local character = LocalPlayer.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	local closestDist = math.huge
	local targetBin = nil

	-- Prioritas 1: Tempat Sampah di dalam Area Bos
	if bossModel then
		for _, descendant in ipairs(bossModel:GetDescendants()) do
			if descendant:IsA("ProximityPrompt") and descendant.Enabled and not isBlacklisted(descendant) then
				local action = string.lower(descendant.ActionText or "")
				local objText = string.lower(descendant.ObjectText or "")
				local name = string.lower(descendant.Name or "")

				if string.find(action, "discard") or string.find(objText, "garbage bin") or string.find(objText, "bin") or string.find(name, "bin") or string.find(name, "discard") then
					table.insert(prompts, descendant)
					return prompts
				end
			end
		end
	end

	-- Prioritas 2: Bak Sampah terdekat di luar area bos yang TIDAK diblacklist
	for _, descendant in ipairs(Workspace:GetDescendants()) do
		if descendant:IsA("ProximityPrompt") and descendant.Enabled and not isBlacklisted(descendant) then
			local action = string.lower(descendant.ActionText or "")
			local objText = string.lower(descendant.ObjectText or "")
			local name = string.lower(descendant.Name or "")

			if string.find(action, "discard") or string.find(objText, "garbage bin") or string.find(objText, "bin") or string.find(name, "bin") or string.find(name, "discard") then
				local promptPart = descendant.Parent:IsA("BasePart") and descendant.Parent or (descendant.Parent:IsA("Model") and descendant.Parent.PrimaryPart)
				if promptPart and rootPart then
					local dist = (rootPart.Position - promptPart.Position).Magnitude
					if dist < closestDist then
						closestDist = dist
						targetBin = descendant
					end
				elseif not targetBin then
					targetBin = descendant
				end
			end
		end
	end

	if targetBin then table.insert(prompts, targetBin) end
	return prompts
end

-- =================================================================
-- 4. CONTROLLER: WALKSPEED (CFRAME BOOST) & JUMPPOWER (VELOCITY IMPULSE)
-- =================================================================

local flying = false
local bodyVelocity, bodyGyro

local function startFlying()
	local character = LocalPlayer.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then return end
	local rootPart = character.HumanoidRootPart

	bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Velocity = Vector3.new(0, 0, 0)
	bodyVelocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
	bodyVelocity.Parent = rootPart

	bodyGyro = Instance.new("BodyGyro")
	bodyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
	bodyGyro.CFrame = rootPart.CFrame
	bodyGyro.Parent = rootPart

	flying = true
end

local function stopFlying()
	flying = false
	if bodyVelocity then bodyVelocity:Destroy() end
	if bodyGyro then bodyGyro:Destroy() end
	local character = LocalPlayer.Character
	if character and character:FindFirstChildOfClass("Humanoid") then
		character:FindFirstChildOfClass("Humanoid").PlatformStand = false
	end
end

-- Listener Permintaan Lompat (Bypass JumpPower Lock Game)
UserInputService.JumpRequest:Connect(function()
	if Config.JumpPower > 50 then
		local character = LocalPlayer.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			local rootPart = character:FindFirstChild("HumanoidRootPart")

			if humanoid and rootPart and humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
				humanoid.UseJumpPower = true
				humanoid.JumpPower = Config.JumpPower
				pcall(function() humanoid.JumpHeight = Config.JumpPower / 3.5 end)

				-- Dorongan Kecepatan Fisik Ke Atas (Impulse Boost)
				rootPart.AssemblyLinearVelocity = Vector3.new(rootPart.AssemblyLinearVelocity.X, Config.JumpPower * 1.1, rootPart.AssemblyLinearVelocity.Z)
			end
		end
	end
end)

-- RenderStepped untuk WalkSpeed CFrame Boost & Fly Controller
RunService.RenderStepped:Connect(function()
	local character = LocalPlayer.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")

	if humanoid then
		humanoid.WalkSpeed = Config.WalkSpeed
		humanoid.UseJumpPower = true
		humanoid.JumpPower = Config.JumpPower
		pcall(function() humanoid.JumpHeight = Config.JumpPower / 3.5 end)
	end

	-- Bypass WalkSpeed (CFrame Move Boost jika game me-reset WalkSpeed)
	if Config.WalkSpeed > 16 and rootPart and humanoid and humanoid.MoveDirection.Magnitude > 0 then
		local extraSpeed = (Config.WalkSpeed - 16) * 0.04
		character:TranslateBy(humanoid.MoveDirection * extraSpeed)
	end

	-- Fly Controller
	if Config.FlyEnabled and rootPart and humanoid then
		if not flying then startFlying() end
		humanoid.PlatformStand = true
		local moveDir = Vector3.new(0, 0, 0)
		local camera = Workspace.CurrentCamera

		if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + camera.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - camera.CFrame.LookVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - camera.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + camera.CFrame.RightVector end
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0, 1, 0) end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDir = moveDir - Vector3.new(0, 1, 0) end

		if moveDir.Magnitude > 0 then moveDir = moveDir.Unit end

		if bodyVelocity then bodyVelocity.Velocity = moveDir * Config.FlySpeed end
		if bodyGyro then bodyGyro.CFrame = camera.CFrame end
	elseif not Config.FlyEnabled and flying then
		stopFlying()
	end
end)

-- =================================================================
-- 5. AUTO CLEAN ENGINE (STRICT BOSS ZONE ISOLATION EXECUTION)
-- =================================================================

local function triggerPrompt(prompt)
	if not prompt or not prompt.Parent then return end
	LastAttemptedPrompt = prompt

	pcall(function()
		if fireproximityprompt then
			fireproximityprompt(prompt)
		else
			prompt:InputHoldBegin()
			task.wait(prompt.HoldDuration or 0.2)
			prompt:InputHoldEnd()
		end
	end)

	task.wait(0.15)
	checkGameWarnings()
end

task.spawn(function()
	while true do
		task.wait(0.3)

		if Config.AutoClean then
			local isEmployee = isPlayerEmployee()

			if not isEmployee then
				Config.AutoClean = false
				if AutoCleanToggleBtn then
					AutoCleanToggleBtn.Text = "OFF"
					AutoCleanToggleBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
				end
				notify("Auto Clean Tidak Dapat Dijalankan", "Anda belum melamar pekerjaan sebagai petugas kebersihan. Silakan melamar pekerjaan terlebih dahulu.", 6)
				continue
			end

			local bossModel = getBossAreaModel()
			local character = LocalPlayer.Character
			if not character or not character:FindFirstChild("HumanoidRootPart") then continue end
			local rootPart = character.HumanoidRootPart

			-- 1. Bersihkan SELURUH "Dirt Clean" di Area Bos
			local dirtPrompts = getValidDirtCleanPrompts(bossModel)

			if #dirtPrompts > 0 then
				for _, prompt in ipairs(dirtPrompts) do
					if not Config.AutoClean then break end
					if prompt and prompt.Parent and prompt.Enabled and not isBlacklisted(prompt) then
						local targetPart = prompt.Parent:IsA("BasePart") and prompt.Parent 
							or (prompt.Parent:IsA("Model") and (prompt.Parent.PrimaryPart or prompt.Parent:FindFirstChildWhichIsA("BasePart")))

						if targetPart then
							pcall(function() rootPart.CFrame = targetPart.CFrame * CFrame.new(0, 2, 0) end)
							task.wait(0.2)
							triggerPrompt(prompt)

							if isBlacklisted(prompt) then
								continue
							else
								task.wait(0.25)
							end
						end
					end
				end
			end

			-- 2. Ambil SELURUH "Garbage Take" KHUSUS DI AREA BOS
			local garbagePrompts = getValidGarbageTakePrompts(bossModel)
			local tookGarbage = false

			if #garbagePrompts > 0 then
				for _, prompt in ipairs(garbagePrompts) do
					if not Config.AutoClean then break end
					if prompt and prompt.Parent and prompt.Enabled and not isBlacklisted(prompt) then
						local targetPart = prompt.Parent:IsA("BasePart") and prompt.Parent 
							or (prompt.Parent:IsA("Model") and (prompt.Parent.PrimaryPart or prompt.Parent:FindFirstChildWhichIsA("BasePart")))

						if targetPart then
							pcall(function() rootPart.CFrame = targetPart.CFrame * CFrame.new(0, 2, 0) end)
							task.wait(0.2)
							triggerPrompt(prompt)

							if isBlacklisted(prompt) then
								continue
							else
								tookGarbage = true
								task.wait(0.25)
							end
						end
					end
				end
			end

			-- 3. Membuang Sampah ke "Garbage Bin Discard"
			if tookGarbage or #garbagePrompts > 0 then
				local binPrompts = getValidGarbageBinPrompts(bossModel)
				if #binPrompts > 0 then
					for _, binPrompt in ipairs(binPrompts) do
						if not Config.AutoClean then break end
						if binPrompt and binPrompt.Parent and binPrompt.Enabled and not isBlacklisted(binPrompt) then
							local targetPart = binPrompt.Parent:IsA("BasePart") and binPrompt.Parent 
								or (binPrompt.Parent:IsA("Model") and (binPrompt.Parent.PrimaryPart or binPrompt.Parent:FindFirstChildWhichIsA("BasePart")))

							if targetPart then
								pcall(function() rootPart.CFrame = targetPart.CFrame * CFrame.new(0, 2, 0) end)
								task.wait(0.25)
								triggerPrompt(binPrompt)
								task.wait(0.35)
							end
						end
					end
				end
			end

			-- 4. VERIFIKASI KETAT SEBELUM MATI: Memastikan Dirt Clean & Garbage Take di Area Bos BENAR-BENAR 0
			task.wait(1.5)
			local checkDirt = getValidDirtCleanPrompts(bossModel)
			local checkGarbage = getValidGarbageTakePrompts(bossModel)

			if #checkDirt > 0 or #checkGarbage > 0 then
				continue
			end

			task.wait(1.0)
			local recheckDirt = getValidDirtCleanPrompts(bossModel)
			local recheckGarbage = getValidGarbageTakePrompts(bossModel)

			if #recheckDirt == 0 and #recheckGarbage == 0 then
				Config.AutoClean = false
				if AutoCleanToggleBtn then
					AutoCleanToggleBtn.Text = "OFF"
					AutoCleanToggleBtn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
				end
				notify("Pembersihan & Buang Sampah Selesai!", "Seluruh Dirt Clean, Garbage Take, dan Garbage Bin Discard di Zona Kerja Bos Anda telah dibersihkan & dibuang total!", 7)
			end
		end
	end
end)

-- =================================================================
-- 6. INTERFACE (DESAIN LEBAR, MODERN, MINIMIZE & CLOSE CONTROL)
-- =================================================================

ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "IndoKosUtilityGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui or LocalPlayer:WaitForChild("PlayerGui")

-- Tombol Floating "Open GUI" saat GUI tertutup/diminimize
local FloatingToggleBtn = Instance.new("TextButton")
FloatingToggleBtn.Name = "FloatingToggleBtn"
FloatingToggleBtn.Size = UDim2.new(0, 42, 0, 42)
FloatingToggleBtn.Position = UDim2.new(0, 15, 0.5, -21)
FloatingToggleBtn.BackgroundColor3 = Color3.fromRGB(33, 36, 44)
FloatingToggleBtn.Text = "IK"
FloatingToggleBtn.TextColor3 = Color3.fromRGB(52, 152, 219)
FloatingToggleBtn.TextSize = 16
FloatingToggleBtn.Font = Enum.Font.SourceSansBold
FloatingToggleBtn.Visible = false
FloatingToggleBtn.Parent = ScreenGui
Instance.new("UICorner", FloatingToggleBtn).CornerRadius = UDim.new(0, 10)

-- Container Utama GUI (Lebar 480px)
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 480, 0, 420)
MainFrame.Position = UDim2.new(0.5, -240, 0.5, -210)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

-- Header Bar Modern
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 45)
Header.BackgroundColor3 = Color3.fromRGB(28, 31, 40)
Header.Parent = MainFrame
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 12)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -110, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.Text = "Indo Kos — Boss Zone Auto Clean & Utilities"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 15
Title.Font = Enum.Font.SourceSansBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BackgroundTransparency = 1
Title.Parent = Header

-- Tombol Minimize (-)
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 32, 0, 30)
MinimizeBtn.Position = UDim2.new(1, -75, 0, 7.5)
MinimizeBtn.Text = "-"
MinimizeBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
MinimizeBtn.TextSize = 20
MinimizeBtn.Font = Enum.Font.SourceSansBold
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(42, 46, 58)
MinimizeBtn.Parent = Header
Instance.new("UICorner", MinimizeBtn).CornerRadius = UDim.new(0, 6)

-- Tombol Close (X)
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 32, 0, 30)
CloseBtn.Position = UDim2.new(1, -38, 0, 7.5)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
CloseBtn.TextSize = 16
CloseBtn.Font = Enum.Font.SourceSansBold
CloseBtn.BackgroundColor3 = Color3.fromRGB(42, 46, 58)
CloseBtn.Parent = Header
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

-- Content Scroll Area (Isi Menu)
local Content = Instance.new("ScrollingFrame")
Content.Size = UDim2.new(1, -24, 1, -60)
Content.Position = UDim2.new(0, 12, 0, 50)
Content.BackgroundTransparency = 1
Content.CanvasSize = UDim2.new(0, 0, 0, 380)
Content.ScrollBarThickness = 5
Content.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Padding = UDim.new(0, 10)
UIListLayout.Parent = Content

-- Logic Minimize & Close Control
local isMinimized = false

MinimizeBtn.MouseButton1Click:Connect(function()
	isMinimized = not isMinimized
	if isMinimized then
		MinimizeBtn.Text = "+"
		Content.Visible = false
		TweenService:Create(MainFrame, TweenInfo.new(0.25), {Size = UDim2.new(0, 480, 0, 45)}):Play()
	else
		MinimizeBtn.Text = "-"
		TweenService:Create(MainFrame, TweenInfo.new(0.25), {Size = UDim2.new(0, 480, 0, 420)}):Play()
		task.delay(0.2, function()
			if not isMinimized then Content.Visible = true end
		end)
	end
end)

CloseBtn.MouseButton1Click:Connect(function()
	MainFrame.Visible = false
	FloatingToggleBtn.Visible = true
	notify("Indo Kos GUI", "GUI Diminimize ke Icon 'IK'. Klik icon untuk membuka kembali.", 3)
end)

FloatingToggleBtn.MouseButton1Click:Connect(function()
	MainFrame.Visible = true
	FloatingToggleBtn.Visible = false
end)

-- Helper Component Builder
local function createToggle(text, defaultState, callback)
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 0, 45)
	container.BackgroundColor3 = Color3.fromRGB(28, 31, 40)
	container.Parent = Content
	Instance.new("UICorner", container).CornerRadius = UDim.new(0, 8)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.72, 0, 1, 0)
	label.Position = UDim2.new(0, 14, 0, 0)
	label.Text = text
	label.TextColor3 = Color3.fromRGB(230, 230, 230)
	label.TextSize = 14
	label.Font = Enum.Font.SourceSans
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.BackgroundTransparency = 1
	label.Parent = container

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 68, 0, 28)
	btn.Position = UDim2.new(1, -80, 0, 8.5)
	btn.Text = defaultState and "ON" or "OFF"
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.TextSize = 13
	btn.Font = Enum.Font.SourceSansBold
	btn.BackgroundColor3 = defaultState and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(231, 76, 60)
	btn.Parent = container
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

	local state = defaultState
	btn.MouseButton1Click:Connect(function()
		state = not state

		if text == "Auto Clean (Zona Bos Saja)" and state == true then
			local isEmployee = isPlayerEmployee()
			if not isEmployee then
				state = false
				btn.Text = "OFF"
				btn.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
				notify("Auto Clean Tidak Dapat Dijalankan", "Anda belum melamar pekerjaan sebagai petugas kebersihan. Silakan melamar pekerjaan terlebih dahulu.", 6)
				callback(false)
				return
			end
		end

		btn.Text = state and "ON" or "OFF"
		btn.BackgroundColor3 = state and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(231, 76, 60)
		callback(state)
	end)

	return btn
end

local function createSlider(text, min, max, default, callback)
	local container = Instance.new("Frame")
	container.Size = UDim2.new(1, 0, 0, 58)
	container.BackgroundColor3 = Color3.fromRGB(28, 31, 40)
	container.Parent = Content
	Instance.new("UICorner", container).CornerRadius = UDim.new(0, 8)

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -24, 0, 22)
	label.Position = UDim2.new(0, 14, 0, 6)
	label.Text = text .. ": " .. tostring(default)
	label.TextColor3 = Color3.fromRGB(230, 230, 230)
	label.TextSize = 14
	label.Font = Enum.Font.SourceSans
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.BackgroundTransparency = 1
	label.Parent = container

	local sliderBg = Instance.new("Frame")
	sliderBg.Size = UDim2.new(1, -28, 0, 8)
	sliderBg.Position = UDim2.new(0, 14, 0, 34)
	sliderBg.BackgroundColor3 = Color3.fromRGB(45, 50, 62)
	sliderBg.Parent = container
	Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(0, 4)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(52, 152, 219)
	fill.Parent = sliderBg
	Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 4)

	local dragging = false
	sliderBg.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local mousePos = UserInputService:GetMouseLocation().X
			local relPos = math.clamp(mousePos - sliderBg.AbsolutePosition.X, 0, sliderBg.AbsoluteSize.X)
			local percent = relPos / sliderBg.AbsoluteSize.X
			local val = math.floor(min + (max - min) * percent)
			fill.Size = UDim2.new(percent, 0, 1, 0)
			label.Text = text .. ": " .. tostring(val)
			callback(val)
		end
	end)
end

-- Render Kontrol GUI Modern
AutoCleanToggleBtn = createToggle("Auto Clean (Zona Bos Saja)", Config.AutoClean, function(v)
	Config.AutoClean = v
end)

createSlider("WalkSpeed (Kecepatan)", 16, 200, Config.WalkSpeed, function(v)
	Config.WalkSpeed = v
end)

createSlider("JumpPower (Lompatan)", 50, 300, Config.JumpPower, function(v)
	Config.JumpPower = v
end)

createToggle("Fly Mode", Config.FlyEnabled, function(v)
	Config.FlyEnabled = v
	if v then startFlying() else stopFlying() end
end)

createSlider("Kecepatan Terbang (Fly)", 20, 200, Config.FlySpeed, function(v)
	Config.FlySpeed = v
end)

notify("Indo Kos Script", "Garbage Take & Discard Scoping Fixed!", 4)
