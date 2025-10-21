#!/bin/bash

# Security Audit Script for Linux Systems
# Author: Nisrina Alya Nabilah
# Date: 2025-09-19

REPORT_FILE="security_report.csv"
TEMP_FILE=$(mktemp)

init_report() {
    echo "Check Category,Item,Status,Details,Suggested Fix" > "$REPORT_FILE"
}

add_to_report() {
    local category="$1"
    local item="$2"
    local status="$3"
    local details="$4"
    local fix="$5"
    
    details=$(echo "$details" | sed 's/,/;/g')
    fix=$(echo "$fix" | sed 's/,/;/g')
    
    echo "$category,$item,$status,$details,$fix" >> "$REPORT_FILE"
    echo "$category,$item,$status,$details,$fix" >> "$TEMP_FILE"
}

display_table() {
    local output_file="security_report.txt"
    
    (
        echo
        echo "Check Category         Item                           Status    Details"
        echo "----------------------------------------------------------------------------------------------------"
        
        while IFS=, read -r category item status details fix; do
            printf "%-21s %-30s %-9s %s\n" "$category" "$item" "$status" "$details"
        done < "$TEMP_FILE"
    ) | tee "$output_file"
    
    echo
    rm -f "$TEMP_FILE"
}

check_permissions() {
    local files=("/etc/passwd" "/etc/shadow" "/etc/sudoers")
    
    for file in "${files[@]}"; do
        if [ -e "$file" ]; then
            local perms=$(stat -c "%a" "$file")
            local readable=$(stat -c "%A" "$file" | cut -c 8)
            local writable=$(stat -c "%A" "$file" | cut -c 9)
            
            if [[ "$perms" == "644" || "$perms" == "640" || "$perms" == "600" ]]; then
                add_to_report "File Permissions" "$file" "PASS" "Permissions $perms (ok)" "None"
            else
                local details="Permissions $perms"
                local fix="chmod 640 $file"
                
                if [ "$readable" = "r" ]; then
                    details="$details, world-readable"
                    fix="$fix"
                fi
                
                if [ "$writable" = "w" ]; then
                    details="$details, world-writable"
                    fix="$fix"
                fi
                
                add_to_report "File Permissions" "$file" "WARN" "$details" "$fix"
            fi
        else
            add_to_report "File Permissions" "$file" "FAIL" "File does not exist" "Check if $file exists"
        fi
    done
}

check_services() {
    local root_process_count=$(ps -u root --no-headers | wc -l)
    add_to_report "Services" "root_process_count" "INFO" "Found $root_process_count processes running as root" "Regularly review processes running as root"
 
    local listening_services=$(ss -tuln | awk 'NR>1 {print $5}' | cut -d: -f2 | sort -u)

    local known_ports=(22 80 443 53 25 587 993 995 143 110)
    local forbidden_ports=(3306 5432 5900 23 6379) 

    for port in $listening_services; do
        if [ -z "$port" ]; then
            continue
        fi

        local process_info=$(ss -tulnp | grep ":$port " | awk '{print $7}' | cut -d\" -f2 | head -n 1)
        local process=${process_info:-"N/A"}

        local is_forbidden=0
        for forbidden in "${forbidden_ports[@]}"; do
            if [ "$port" = "$forbidden" ]; then
                is_forbidden=1
                break
            fi
        done

        if [ $is_forbidden -eq 1 ]; then
            add_to_report "Services" "port_$port" "FAIL" "Forbidden port $port ($process) is open" "CRITICAL! This port poses a major security risk. Close it immediately."
            continue 
        fi
        local is_known=0
        for known in "${known_ports[@]}"; do
            if [ "$port" = "$known" ]; then
                is_known=1
                break
            fi
        done

        if [ $is_known -eq 0 ]; then
            add_to_report "Services" "port_$port" "WARN" "Unknown service listening on port $port: $process" "Investigate and disable if unnecessary: sudo ss -tulnp | grep :$port"
        else
            add_to_report "Services" "port_$port" "PASS" "Known service listening on port $port: $process" "Ensure only necessary services run"
        fi
    done
}

check_users() {
    local no_password=$(awk -F: '($2 == "" ) {print $1}' /etc/shadow 2>/dev/null)
    if [ -n "$no_password" ]; then
        for user in $no_password; do
            add_to_report "Users" "$user" "WARN" "Account has no password set" "Set a strong password or lock account: sudo passwd -l $user"
        done
    else
        add_to_report "Users" "no_password" "PASS" "No accounts without password" "None"
    fi
    
    local uid0_users=$(awk -F: '($3 == 0) {print $1}' /etc/passwd)
    for user in $uid0_users; do
        if [ "$user" != "root" ]; then
            add_to_report "Users" "$user" "FAIL" "Account has UID 0 (root privileges)" "Remove UID 0 from this account: sudo usermod -u <new-uid> $user"
        fi
    done
    
    local current_date=$(date +%s)
    local inactive_users=""
    
    for user in $(cut -d: -f1 /etc/passwd); do
        local last_login=$(last -n 1 -F "$user" | awk 'NR==1 {if ($0 !~ /still logged in/) print $0}' | head -1)
        if [ -n "$last_login" ]; then
            local login_date=$(date -d "$(echo "$last_login" | awk '{print $5" "$6" "$7" "$8}')" +%s 2>/dev/null)
            if [ -n "$login_date" ]; then
                local days_since_login=$(( (current_date - login_date) / 86400 ))
                if [ $days_since_login -gt 90 ]; then
                    inactive_users="$inactive_users $user($days_since_login days)"
                fi
            fi
        fi
    done
    
    if [ -n "$inactive_users" ]; then
        add_to_report "Users" "inactive_users" "WARN" "Inactive users: $inactive_users" "Consider disabling or deleting inactive accounts"
    else
        add_to_report "Users" "inactive_users" "PASS" "No inactive users found" "None"
    fi
}

check_logs() {
    local auth_log=""
    if [ -f "/var/log/auth.log" ]; then
        auth_log="/var/log/auth.log"
    elif [ -f "/var/log/secure" ]; then
        auth_log="/var/log/secure"
    else
        add_to_report "Logs" "auth_log" "FAIL" "Could not find auth log file" "Check if /var/log/auth.log or /var/log/secure exists"
        return
    fi
    
    local failed_logins=$(journalctl _SYSTEMD_UNIT=ssh.service --since "24 hours ago" | grep -c "authentication failure")
    
    if [ "$failed_logins" -gt 10 ]; then
        add_to_report "Logs" "$auth_log" "WARN" "$failed_logins failed login attempts in last 24h" "Check for brute-force attack, enforce fail2ban or similar protection"
    else
        add_to_report "Logs" "$auth_log" "PASS" "$failed_logins failed login attempts in last 24h" "None"
    fi
    
    local sudo_failures=$(grep "sudo:.*authentication failure" "$auth_log" | wc -l)
    if [ "$sudo_failures" -gt 5 ]; then
        add_to_report "Logs" "sudo_failures" "WARN" "$sudo_failures sudo authentication failures" "Review sudo access and user permissions"
    fi
}

additional_checks() {
    local world_writable=$(find /etc /bin /sbin /usr/bin /usr/sbin -type f -perm -o+w 2>/dev/null | head -5)
    if [ -n "$world_writable" ]; then
        add_to_report "Additional Checks" "world_writable" "WARN" "World-writable files found in system directories: $world_writable" "Review and fix permissions: chmod o-w <file>"
    else
        add_to_report "Additional Checks" "world_writable" "PASS" "No world-writable files in system directories" "None"
    fi
    
    local ssh_protocol=$(grep -i "Protocol" /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}')
    if [ "$ssh_protocol" != "2" ] && [ -n "$ssh_protocol" ]; then
        add_to_report "Additional Checks" "ssh_protocol" "WARN" "SSH Protocol is $ssh_protocol (should be 2)" "Set Protocol 2 in /etc/ssh/sshd_config"
    else
        add_to_report "Additional Checks" "ssh_protocol" "PASS" "SSH Protocol is 2" "None"
    fi
    
    local permit_empty=$(grep -i "PermitEmptyPasswords" /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}')
    if [ "$permit_empty" = "yes" ]; then
        add_to_report "Additional Checks" "ssh_empty_passwords" "FAIL" "SSH permits empty passwords" "Set PermitEmptyPasswords no in /etc/ssh/sshd_config"
    else
        add_to_report "Additional Checks" "ssh_empty_passwords" "PASS" "SSH does not permit empty passwords" "None"
    fi
}

main() {
    init_report
    
    check_permissions
    check_services
    check_users
    check_logs
    additional_checks
    
    display_table
}

main "$@"