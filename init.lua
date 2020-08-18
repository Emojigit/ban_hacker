local mod_storage = minetest.get_mod_storage()
local have_mod = {}
have_mod.mail = minetest.get_modpath("mail")
have_mod.default = minetest.get_modpath("default")
local worlddir = minetest.get_worldpath()
local rc = {}
rc.warn = {}
rc.warn_count = {}
rc.ban = {}
local warn_time = 5-2
local warn_second = 300
local ban_second = 300
local banip_second = 600
if have_mod.mail and core.settings:get("name") then
	rc.send_mail = function(name, ip, time, type_login)
		local title = "Ban Hacker log: "..name.." ["..ip.."] at "..tostring(time)
		local text_m1 = "Type: "
		local text_0 = text_m1..(type_login or "Ban")
		local text_1 = "\nA user tried to hack the server at "..tostring(time)..".\n"..name.." ["..ip.."]\n"
		local text_3 = "\nDO NOT REPLY THIS MESSAGE\n\nFrom,\nSystem"
		local text = text_0..text_1..(text_2 or "")..text_3
		mail.send("Ban Hackers System",core.settings:get("name"),title,text)
	end
end

rc.record = function(target)
	local type = "Warn"
	if not(rc.warn_count[target]) then
		rc.warn_count[target] = 0
	end
	if rc.warn[target] and ((rc.warn[target] + warn_second) > os.time(os.date("!*t"))) then
		rc.warn_count[target] = rc.warn_count[target] + 1
	end
	rc.warn[target] = os.time(os.date("!*t"))
	if rc.warn_count[target] > warn_time then
		rc.ban[target] = os.time(os.date("!*t"))
		local type = "Ban"
	end
	minetest.log("action", "[ban_hacker] Recored `"..target.."`, type "..type..".")
	rc.save(rc.ban)
end

rc.save = function(data)
	mod_storage:set_string("ban_rc", minetest.serialize(data))
end

rc.get = function()
	return minetest.deserialize(mod_storage:get_string("ban_rc"))
end

-------------------------------------

rc.ban = rc.get() or {}

-------------------------------------

minetest.register_on_authplayer(function(name, ip, is_success)
	if not(is_success) then
		rc.record(name)
		rc.record(ip)
		if (rc.ban[name] or rc.ban[ip]) and rc.send_mail then
			rc.send_mail(name, ip, os.date('%Y-%m-%d %H:%M:%S'))
		end
		minetest.log("action", "[ban_hacker] Wrong password from "..name.." ["..ip.."], recorded.")
	end
end)

minetest.register_on_prejoinplayer(function(name, ip)
	rc.ban[name] = rc.ban[name] or 0
	rc.ban[ip] = rc.ban[ip] or 0
	if ((rc.ban[name] + ban_second > os.time(os.date("!*t"))) or (rc.ban[ip] + banip_second > os.time(os.date("!*t")))) and not(ip == "127.0.0.1") then
		minetest.log("action", "[ban_hacker] Rejected connect from "..name.." ["..ip.."]")
		if (rc.ban[ip] + banip_second > os.time(os.date("!*t"))) then
			rc.record(ip)
			rc.send_mail(name, ip, os.date('%Y-%m-%d %H:%M:%S'), "Tried to join")
		end
		return "Too many wrong password for this account or IP.".."\nTry again later."
	end
end)


