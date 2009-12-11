-- $Rev: 1662 $
-- $LastChangedDate: 2009-09-11 19:28:17 -0700 (Fri, 11 Sep 2009) $
-- $LastChangedBy: TomyLobo $

local WIRE_SCROLL_SPEED = 0.5
local WIRE_BLINKS_PER_SECOND = 2
local CurPathEnt = {}
local Wire_DisableWireRender = 2 --bug with mode 0 and gmod2007beta

WIRE_CLIENT_INSTALLED = 1

Msg("loading materials\n")
list.Add( "WireMaterials", "cable/rope_icon" )
list.Add( "WireMaterials", "cable/cable2" )
list.Add( "WireMaterials", "cable/xbeam" )
list.Add( "WireMaterials", "cable/redlaser" )
list.Add( "WireMaterials", "cable/blue_elec" )
list.Add( "WireMaterials", "cable/physbeam" )
list.Add( "WireMaterials", "cable/hydra" )
--new wire materials by Acegikmo
list.Add( "WireMaterials", "arrowire/arrowire" )
list.Add( "WireMaterials", "arrowire/arrowire2" )

local mats = {
	["tripmine_laser"] = Material("tripmine_laser"),
	["Models/effects/comball_tape"] = Material("Models/effects/comball_tape")
}
for _,mat in pairs(list.Get( "WireMaterials" )) do
	Msg("loading material: ",mat,"\n")
	mats[mat] = Material(mat)
end
local function getmat( mat )
	if mats[mat] == nil then
		mats[mat] = Material(mat)
	end
	return mats[mat]
end
local beam_mat = mats["tripmine_laser"]
local beamhi_mat = mats["Models/effects/comball_tape"]

function Wire_Render(ent)
	if (not ent:IsValid()) then return end
	if (Wire_DisableWireRender == 1) then return end

	if (Wire_DisableWireRender == 0) then
		local path_count = ent:GetNetworkedBeamInt("wpn_count") or 0
		if (path_count <= 0) then return end

		local w,f = math.modf(CurTime()*WIRE_BLINKS_PER_SECOND)
		local blink = nil
		if (f < 0.5) then
			blink = ent:GetNetworkedBeamString("BlinkWire")
		end

		for i = 1,path_count do
			local path_name = ent:GetNetworkedBeamString("wpn_" .. i)
			if (blink ~= path_name) then
				local net_name = "wp_"..path_name
				local len = ent:GetNetworkedBeamInt(net_name) or 0

				if (len > 0) then
					local start = ent:GetNetworkedBeamVector(net_name .. "_start")
					if (ent:IsValid()) then start = ent:LocalToWorld(start) end
					local color_v = ent:GetNetworkedBeamVector(net_name .. "_col")
					local color = Color(color_v.x, color_v.y, color_v.z, 255)
					local width = ent:GetNetworkedBeamFloat(net_name .. "_width")

					local scroll = CurTime()*WIRE_SCROLL_SPEED

					render.SetMaterial(getmat(ent:GetNetworkedBeamString(net_name .. "_mat")))
					render.StartBeam(len+1)
					render.AddBeam(start, width, scroll, color)

					for j=1,len do
						local node_ent = ent:GetNetworkedBeamEntity(net_name .. "_" .. j .. "_ent")
						local endpos = ent:GetNetworkedBeamVector(net_name .. "_" .. j .. "_pos")
						if (node_ent:IsValid()) then
							endpos = node_ent:LocalToWorld(endpos)

							scroll = scroll+(endpos-start):Length()/10

							render.AddBeam(endpos, width, scroll, color)

							start = endpos
						end
					end
					render.EndBeam()
				end
			end
		end

	else
		local p = ent.ppp
		if p == nil then p = {next = -100} end

		if p.next < CurTime() then
			p.next = CurTime() + 0.25
			p.paths = {}

			local path_count = ent:GetNetworkedBeamInt("wpn_count") or 0
			if (path_count <= 0) then return end

			for i = 1,path_count do
				local x = {}
				local path_name = ent:GetNetworkedBeamString("wpn_" .. i)
				x.path_name = path_name
				local net_name = "wp_"..path_name
				local len = ent:GetNetworkedBeamInt(net_name) or 0

				if (len > 0) then

					local start = ent:GetNetworkedBeamVector(net_name .. "_start")
					x.startx = start
					if (ent:IsValid()) then start = ent:LocalToWorld(start) end
					local color_v = ent:GetNetworkedBeamVector(net_name .. "_col")
					local color = Color(color_v.x, color_v.y, color_v.z, 255)
					local width = ent:GetNetworkedBeamFloat(net_name .. "_width")

					local scroll = CurTime()*WIRE_SCROLL_SPEED

					x.material = getmat(ent:GetNetworkedBeamString(net_name .. "_mat"))
					x.startbeam = len + 1
					x.start = start
					x.width = width
					x.scroll = scroll
					x.color = color
					x.beams = {}

					for j=1,len do
						local v = {}
						local node_ent = ent:GetNetworkedBeamEntity(net_name .. "_" .. j .. "_ent")
						local endpos = ent:GetNetworkedBeamVector(net_name .. "_" .. j .. "_pos")
						v.node_ent = node_ent
						v.node_endpos = endpos
						if (node_ent:IsValid()) then
							endpos = node_ent:LocalToWorld(endpos)

							scroll = scroll+(endpos-start):Length()/10

							v.endpos = endpos
							v.width = width
							v.scroll = scroll
							v.color = color
							table.insert(x.beams, v)

							start = endpos
						end
					end

					table.insert(p.paths, x)

				end
			end

			ent.ppp = p
		end


		local w,f = math.modf(CurTime()*WIRE_BLINKS_PER_SECOND)
		local blink = f < 0.5
		local blinkname = ent:GetNetworkedBeamString("BlinkWire")
		for _,k in ipairs(p.paths) do
			if not (blink and blinkname == k.path_name) then
				k.scroll = CurTime()*WIRE_SCROLL_SPEED
				k.start = ent:LocalToWorld(k.startx)
				render.SetMaterial(k.material)
				render.StartBeam(k.startbeam)
				render.AddBeam(k.start, k.width, k.scroll, k.color)
				for _,v in ipairs(k.beams) do
					if (v.node_ent:IsValid()) then
						local endpos = v.node_ent:LocalToWorld(v.node_endpos)
						local scroll = k.scroll+(endpos-k.start):Length()/10
						render.AddBeam(endpos, v.width, scroll, v.color)
					end
				end
				render.EndBeam()
			end
		end

	end
end


local function Wire_GetWireRenderBounds(ent)
	if (not ent:IsValid()) then return end

	local paths = ent.WirePaths
	local bbmin = ent:OBBMins()
	local bbmax = ent:OBBMaxs()

	local path_count = ent:GetNetworkedBeamInt("wpn_count") or 0
	if (path_count > 0) then
		for i = 1,path_count do
			local path_name = ent:GetNetworkedBeamString("wpn_" .. i)
			local net_name = "wp_"..path_name
			local len = ent:GetNetworkedBeamInt(net_name) or 0

			if (len > 0) then
				for j=1,len do
					local node_ent = ent:GetNetworkedBeamEntity(net_name .. "_" .. j .. "_ent")
					local nodepos = ent:GetNetworkedBeamVector(net_name .. "_" .. j .. "_pos")
					if (node_ent:IsValid()) then
						nodepos = ent:WorldToLocal(node_ent:LocalToWorld(nodepos))

						if (nodepos.x < bbmin.x) then bbmin.x = nodepos.x end
						if (nodepos.y < bbmin.y) then bbmin.y = nodepos.y end
						if (nodepos.z < bbmin.z) then bbmin.z = nodepos.z end
						if (nodepos.x > bbmax.x) then bbmax.x = nodepos.x end
						if (nodepos.y > bbmax.y) then bbmax.y = nodepos.y end
						if (nodepos.z > bbmax.z) then bbmax.z = nodepos.z end
					end
				end
			end
		end
	end

	if (ent.ExtraRBoxPoints) then
		for _,point_l in ipairs( ent.ExtraRBoxPoints ) do
			local point = point_l
			if (point.x < bbmin.x) then bbmin.x = point.x end
			if (point.y < bbmin.y) then bbmin.y = point.y end
			if (point.z < bbmin.z) then bbmin.z = point.z end
			if (point.x > bbmax.x) then bbmax.x = point.x end
			if (point.y > bbmax.y) then bbmax.y = point.y end
			if (point.z > bbmax.z) then bbmax.z = point.z end
		end
	end

	return bbmin, bbmax
end


function Wire_UpdateRenderBounds(ent)
	local bbmin, bbmax = Wire_GetWireRenderBounds(ent)
	ent:SetRenderBounds(bbmin, bbmax)
end

local function WireDisableRender(pl, cmd, args)
	if args[1] then
		Wire_DisableWireRender = tonumber(args[1])
	end
	Msg("\nWire DisableWireRender/WireRenderMode = "..tostring(Wire_DisableWireRender).."\n")
end
concommand.Add( "cl_Wire_DisableWireRender", WireDisableRender )
concommand.Add( "cl_Wire_SetWireRenderMode", WireDisableRender )


function Wire_DrawTracerBeam( ent, beam_num, hilight, beam_length )
	local beam_length = beam_length or ent:GetBeamLength(beam_num)
	if (beam_length > 0) then

		local x, y = 0, 0
		if (ent.GetSkewX and ent.GetSkewY) then
			x, y = ent:GetSkewX(beam_num), ent:GetSkewY(beam_num)
		end

		local start, ang = ent:GetPos(), ent:GetAngles()

		if (ent.ls != start or ent.la != ang or ent.ll != beam_length or ent.lx != x or ent.ly != y) then
			ent.ls, ent.la = start, ang

			if (ent.ll != beam_length or ent.lx != x or ent.ly != y) then
				ent.ll, ent.lx, ent.ly = beam_length, x, y

				if (x == 0 and y == 0) then
					ent.endpos = start + (ent:GetUp() * beam_length)
				else
					local skew = Vector(x, y, 1)
					skew = skew*(beam_length/skew:Length())
					local beam_x = ent:GetRight()*skew.x
					local beam_y = ent:GetForward()*skew.y
					local beam_z = ent:GetUp()*skew.z
					ent.endpos = start + beam_x + beam_y + beam_z
				end
				ent.ExtraRBoxPoints = ent.ExtraRBoxPoints or {}
				ent.ExtraRBoxPoints[beam_num] = ent:WorldToLocal(ent.endpos)
			else
				ent.endpos = ent:LocalToWorld(ent.ExtraRBoxPoints[beam_num])
			end
		end

		local trace = {}
		trace.start = start
		trace.endpos = ent.endpos
		trace.filter = { ent }
		if ent:GetNetworkedBool("TraceWater") then trace.mask = MASK_ALL end
		trace = util.TraceLine(trace)

		render.SetMaterial(beam_mat)
		render.DrawBeam(start, trace.HitPos, 6, 0, 10, Color(ent:GetColor()))
		if (hilight) then
			render.SetMaterial(beamhi_mat)
			render.DrawBeam(start, trace.HitPos, 6, 0, 10, Color(255,255,255,255))
		end
	end
end

hook.Add("InitPostEntity", "language_strings", function()
	for class, tbl in pairs(scripted_ents.GetList()) do
		if tbl.t.PrintName and tbl.t.PrintName ~= "" then
			language.Add( class, tbl.t.PrintName )
		end
	end
end)

if not CanRunConsoleCommand then
	function CanRunConsoleCommand() return false end
	hook.Add("OnEntityCreated", "CanRunConsoleCommand", function(ent)
		if not ValidEntity(ent) then return end
		if ent ~= LocalPlayer() then return end

		function CanRunConsoleCommand() return true end
		hook.Remove("OnEntityCreated", "CanRunConsoleCommand")
	end)
end

/******************************* gmod_tool_auto *******************************/

-- Separate table so they can be cycled with wire_adv and wire_debugger.
local wiremod_mappings = {
	-- wiremod+advdupe
	gmod_wire_gate = "wire_gates",
	gmod_wire_cameracontroller = "wire_cam",
	gmod_wire_cd_lock = "wire_cd_ray",
	gmod_wire_vectorthruster = "wire_vthruster",
	gmod_adv_dupe_paster = "adv_duplicator",
}

local ent_tool_mappings = {
	-- gmod
	prop_physics = { "easy_precision", "!weapon_physgun" },
	func_physbox = { "easy_precision", "!weapon_physgun" },

	-- resource distribution
	resource_node = "resourcenodes",
	rd_pump = "pumps",

	-- life support
	other_screen = "ls3_other",
	other_lamp = "ls3_other_lights",
	other_spotlight = "ls3_other_lights",

	-- spacebuild
	base_terraformer = "sb_terraformer",
	nature_dev_tree = "sb_dev_plants",
	base_default_res_module = "sbep_res_mods",
}

local ent_tool_patterns = {
	{"^.*$", ent_tool_mappings},

	-- gmod
	{"^prop_", "!weapon_physgun"},
	bogus = {"^gmod_(.*)$", true}, -- true means "pass pattern result". The bogus index ensures that this always is iterated last.

	-- wiremod
	{"^gmod_.*$", { wiremod_mappings, "wire_adv", "wire_debugger" }},
	{"^gmod_(wire_.*)$", { true, "wire_adv", "wire_debugger" }},

	-- resource distribution
	{"^rd_.*_valve$", "valves"},

	-- life support
	{"^storage_.*$", "ls3_receptacles"},
	{"^generator_.*$", "ls3_energysystems"},
	{"^other_.*$", "ls3_environmental_control"},
	{"^base_.*$", "ls3_environmental_control"},
	{"^nature_.*$", "ls3_environmental_control"},
}

local function pattern_mappings(class, ntapped)
	local function maprep(replacement, result, ...)
		if not result then return end

		local tp = type(replacement)
		if replacement == true then
			return result
		elseif tp == "string" then
			return replacement
		elseif tp == "table" then
			local narray = #replacement
			if narray == 0 then
				return maprep(replacement[result], result, ...)
			else
				return maprep(replacement[((ntapped-1) % narray)+1], result, ...)
			end
		elseif tp == "function" then
			return maprep(replacement(ntapped, result, ...), result, ...)
		end
	end

	for _,pattern,replacement in pairs_map(ent_tool_patterns, unpack) do
		local ret = maprep(replacement, class:match(pattern))
		if ret then return ret end
	end
end

local lastent = NULL
local ntapped = 0

concommand.Add("gmod_tool_auto", function(ply, command, args)
	local trace = ply:GetEyeTrace()
	local ent = trace.Entity
	local class = ent:GetClass()

	if ent ~= lastent then
		lastent = ent
		ntapped = 0
	end
	ntapped = ntapped + 1
	local toolmode = pattern_mappings(class, ntapped)

	if not toolmode then return end
	local weapon = toolmode:match("^!(.*)$")
	if weapon then
		RunConsoleCommand( "use", weapon )
		return
	end

	RunConsoleCommand( "gmod_tool", toolmode )
	RunConsoleCommand( "tool_" .. toolmode )
end)

-- extension interface:
gmod_tool_auto = {}

local lastuniqueid = 0
--- Adds a pattern to be matched against the entity class for gmod_tool_auto. Good for packs with some kind of naming scheme.
--- Returns a uniqueid that can be used to remove the pattern later.
---
--- replacement can be:
---   true: Use the first pattern capture as the toolmode
---   string: Use this string as the toolmode.
---   table: Look up first pattern capture and use the result as the  If nothing was found, the match is ignored
---   array table: Cycles through the table's entries when using gmod_tool_auto multiple times on the same entity.
---   function(ntapped, capture1, capture2, ...): pass the captures to a function, along with a number that specifies how often gmod_tool_auto was used on the same entity.
---
--- The table/array lookups and function calls are done recursively.
function gmod_tool_auto.AddPattern(pattern, replacement, index)
	lastuniqueid = lastuniqueid + 1
	table.insert(ent_tool_patterns, index or #ent_tool_patterns+1, { pattern, replacement, lastuniqueid })
	return lastuniqueid
end

--- Removes a pattern given by uniqueid
function gmod_tool_auto.RemovePattern(uniqueid)
	for i,pattern,replacement,uid in ipairs_map(ent_tool_patterns, unpack) do
		if uniqueid == uid then
			table.remove(ent_tool_patterns, i)
			return pattern, replacement
		end
	end
end

--- Maps a single entity class for gmod_tool_auto. Good for single tools and tools that break your pack's norm.
--- "replacement" can be the same as in gmod_tool_auto.AddPattern.
function gmod_tool_auto.AddSimple(class, replacement)
	ent_tool_mappings[class] = replacement
end

--- Adds all mappings in the given table to the table of single mappings.
--- This basically corresponds to a bunch of calls to gmod_tool_auto.AddSimple.
function gmod_tool_auto.AddSimpleMultiple(mappings)
	table.Merge(ent_tool_mappings, mappings)
end

--- Returns the pattern table and the table of single mappings.
function gmod_tool_auto.GetTables()
	return ent_tool_patterns, ent_tool_mappings
end
