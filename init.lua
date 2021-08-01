local mod_storage = minetest.get_mod_storage()
local have_mod = {}
have_mod.mail = minetest.get_modpath("mail")
have_mod.default = minetest.get_modpath("default")
local worlddir = minetest.get_worldpath()
local bh_rc = {}
bh_rc.warn = {}
bh_rc.warn_count = {}
bh_rc.ban = {}
local warn_time = 5-2
local warn_second = 300
local ban_second = 300
local banip_second = 600
if have_mod.mail and core.settings:get("ban_hacker_mail") then
	bh_rc.send_mail = function(name, ip, time, type_login)
		local title = "Ban Hacker log: "..name.." ["..ip.."] at "..tostring(time)
		local text_m1 = "Type: "
		local text_0 = text_m1..(type_login or "Ban")
		local text_1 = "\nA user tried to hack the server at "..tostring(time)..".\n"..name.." ["..ip.."]\n"
		local text_3 = "\nDO NOT REPLY THIS MESSAGE\n\nFrom,\nSystem"
		local text = text_0..text_1..(text_2 or "")..text_3
		mail.send("Ban Hackers System",core.settings:get("name"),title,text)
	end
end

bh_rc.record = function(target)
	local type = "Warn"
	if not(bh_rc.warn_count[target]) then
		bh_rc.warn_count[target] = 0
	end
	if bh_rc.warn[target] and ((bh_rc.warn[target] + warn_second) > os.time(os.date("!*t"))) then
		bh_rc.warn_count[target] = bh_rc.warn_count[target] + 1
	end
	bh_rc.warn[target] = os.time(os.date("!*t"))
	if bh_rc.warn_count[target] > warn_time then
		bh_rc.ban[target] = os.time(os.date("!*t"))
		local type = "Ban"
	end
	minetest.log("action", "[ban_hacker] Recored `"..target.."`, type "..type..".")
	bh_rc.save(bh_rc.ban)
end

bh_rc.save = function(data)
	mod_storage:set_string("ban_rc", minetest.serialize(data))
end

bh_rc.get = function()
	return minetest.deserialize(mod_storage:get_string("ban_rc"))
end

-------------------------------------

bh_rc.ban = bh_rc.get() or {}

-------------------------------------

minetest.register_on_authplayer(function(name, ip, is_success)
	if not(is_success) then
		bh_rc.record(name)
		bh_rc.record(ip)
		if (bh_rc.ban[name] or bh_rc.ban[ip]) and bh_rc.send_mail then
			bh_rc.send_mail(name, ip, os.date('%Y-%m-%d %H:%M:%S'))
		end
		minetest.log("action", "[ban_hacker] Wrong password from "..name.." ["..ip.."], recorded.")
	end
end)

minetest.register_on_prejoinplayer(function(name, ip)
	bh_rc.ban[name] = bh_rc.ban[name] or 0
	bh_rc.ban[ip] = bh_rc.ban[ip] or 0
	if ((bh_rc.ban[name] + ban_second > os.time(os.date("!*t"))) or (bh_rc.ban[ip] + banip_second > os.time(os.date("!*t")))) and not(ip == "127.0.0.1") then
		minetest.log("action", "[ban_hacker] Rejected connect from "..name.." ["..ip.."]")
		if (bh_rc.ban[ip] + banip_second > os.time(os.date("!*t"))) then
			bh_rc.record(ip)
			bh_rc.send_mail(name, ip, os.date('%Y-%m-%d %H:%M:%S'), "Tried to join")
		end
		return "Too many wrong password for this account or IP.".."\nTry again later."
	end
end)


