#!/usr/bin/ruby -w
#
require 'ldap'


def get_sorted_users(infile, srv, usr, pwd)
	port = 389
	conn = LDAP::Conn.new(srv, port)
	conn.set_option(LDAP::LDAP_OPT_PROTOCOL_VERSION,3)
	conn.bind(usr, pwd)

	user_list = Array.new()

	file = File.new(infile, "r")
	while (line = file.gets)
		line = line.chomp
		usr = line.split("\t")
		
		att = userlu(conn, "sAMAccountName="+usr[0])

		if att != nil then
			mgr = att['manager'][0] # get the manager 
			amgr = mgr.split("OU=") # strip off the OU part
			
			mgr = amgr[0][0..-2] 	# remove the trailing ', '
			mgr = mgr.gsub("\\", "")	# remove slashes

			mgr = mgr.gsub("(", "\\(")	# escape parens
			mgr = mgr.gsub(")", "\\)")
			mgr_att = userlu(conn, mgr)
			# print "Manager: " + mgr + "\n"
			mgr_email = mgr_att['mail'][0]
			# print "Manager email: " + mgr_email + "\n"

			user_list << [usr[0], att['cn'][0],  att['mail'][0], mgr[3..-1], mgr_email]
		end
	end
	file.close

	user_list = user_list.sort_by { |u| u[3] }

	# iterate over the array and print the contents
	#
	print "Showing the users in the big array now...\n"
	user_list.each do |u|
		printf("%s\t%s\t%s\t%s\t%s\n", u[0], u[1], u[2], u[3], u[4])
	end

end

def userlu(con, u)
	print "Looking up : " + u + "\n"
	user = nil

	base_dn= "ou=users,ou=accounts,dc=up,dc=corp,dc=upc"
	attrs = ['cn', 'sAMAccountName', 'mail', 'manager']
	# results = con.search2(base_dn, LDAP::LDAP_SCOPE_SUBTREE, '(sAMAccountName='+u[0]+')', attrs)
	results = con.search2(base_dn, LDAP::LDAP_SCOPE_SUBTREE, u, attrs)

	# puts results.inspect
	if results.length == 1 then
		user = results[0]
		# printf( "cn = %s, manager = %s\n", user["cn"], user["manager"])
	else
		print "*** Could not locate #{u[0]} in LDAP\n"
	end
	return user
end


if ARGV.length != 3 then
	print "adlu.rb\n"
	print "---------------------------------------------------------------------\n"
	print "Usage: \n" 
	print "\tadlu.rb <file> <password>\n"
	print "Where: \n\tfile - the input file of user id's extracted from AppWatch\n"
	print "\tuser - user id for making Active Directory lookups\n"
	print "\tpassword - the password user used to connect to Active Directory\n\n"
	exit
end


inputfile = ARGV[0]
who = ARGV[1]
cred = ARGV[2]
ldap_srv = "ldap.example.com"
mail_srv = "smtp.example.com"

get_sorted_users(inputfile, ldap_srv, who, cred)



