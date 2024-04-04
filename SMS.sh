#!/bin/bash

# Function to validate a date
vvalidate_date() {
    local input_date=$1
    local format_regex="^[0-9]{4}-[0-9]{2}-[0-9]{2}$"
    local leap_year=false

    if ! [[ $input_date =~ $format_regex ]]; then
        echo "Invalid date format. Please enter in YYYY-MM-DD format."
        return 1
    fi

    local current_year=$(date +%Y)
    local year=$(echo $input_date | cut -d '-' -f 1)
    local month=$(echo $input_date | cut -d '-' -f 2)
    local day=$(echo $input_date | cut -d '-' -f 3)

    # Calculate age
    local age=$((current_year - year))

    if (( $age < 3 )); then
        echo "Age must be 3 years or older."
        return 1
    fi

    if (( $year % 4 == 0 && ($year % 100 != 0 || $year % 400 == 0) )); then
        leap_year=true
    fi

    case $month in
        01|03|05|07|08|10|12)
            if (( $day < 1 || $day > 31 )); then
                echo "Invalid day for the given month. Day should be between 1 and 31."
                return 1
            fi
            ;;
        04|06|09|11)
            if (( $day < 1 || $day > 30 )); then
                echo "Invalid day for the given month. Day should be between 1 and 30."
                return 1
            fi
            ;;
        02)
            if $leap_year; then
                if (( $day < 1 || $day > 29 )); then
                    echo "Invalid day for the given month (February in a leap year). Day should be between 1 and 29."
                    return 1
                fi
            else
                if (( $day < 1 || $day > 28 )); then
                    echo "Invalid day for the given month (February in a non-leap year). Day should be between 1 and 28."
                    return 1
                fi
            fi
            ;;
        *)
            echo "Invalid month. Month should be between 01 and 12."
            return 1
            ;;
    esac
}

# Database connection details
hostname="Localhost"
port="3306"
username="demo_aash"
password="Ru#@1i4jl8Sf"
dbname="demo_phptest"

# Function to display menu options
display_menu() {
    clear
    echo "Student Management System"
    echo "1. View all students"
    echo "2. Add a new student"
    echo "3. Edit a student"
    echo "4. Delete a student"
    echo "5. Exit"
    echo "Enter your choice:"
}

# Function to view all students with pagination
view_students() {
    page=1
    page_size=6 # Adjust as needed
    while true; do
        clear
        total_students=$(mysql -h "$hostname" -P "$port" -u "$username" -p"$password" "$dbname" -se "SELECT COUNT(*) FROM StudentRecords;")
        total_pages=$(( ($total_students + $page_size - 1) / $page_size ))
        echo "List of Students (Page $page/$total_pages):"
        mysql -h "$hostname" -P "$port" -u "$username" -p"$password" "$dbname" -e "SELECT student_id, full_name FROM StudentRecords LIMIT $((($page - 1) * $page_size)), $page_size;"
        echo ""
        if [ $page -gt 1 ]; then
            echo "P: Previous Page"
        fi
        if [ $page -lt $total_pages ]; then
            echo "N: Next Page"
        fi
        echo "Enter student ID to view full details (0 to go back to menu):"
        read input
        if [ "$input" == "0" ]; then
            break
        elif [[ "$input" =~ ^[0-9]+$ ]]; then
            student_id=$input
            student_exists=$(mysql -h "$hostname" -P "$port" -u "$username" -p"$password" "$dbname" -se "SELECT COUNT(*) FROM StudentRecords WHERE student_id=$student_id;")
            if [ "$student_exists" -eq 1 ]; then
                view_student_details "$student_id"
            else
                echo "Invalid student ID. Please enter a valid ID."
                read -p "Press Enter to continue..."
            fi
        elif [ "$input" == "N" ] && [ $page -lt $total_pages ]; then
            ((page++))
        elif [ "$input" == "P" ] && [ $page -gt 1 ]; then
            ((page--))
        else
            echo "Invalid input. Please enter a valid student ID or navigation command."
            read -p "Press Enter to continue..."
        fi
    done
}

# Function to view full details of a student by ID
view_student_details() {
    clear
    student_id=$1
    echo "Student Details (ID: $student_id):"
    mysql -h "$hostname" -P "$port" -u "$username" -p"$password" "$dbname" -e "SELECT * FROM StudentRecords WHERE student_id=$student_id;"
    echo ""
    echo "1. Edit student details"
    echo "2. Go back to student list"
    echo "Enter your choice:"
    read choice
    case $choice in
        1) edit_student "$student_id" ;;
        2) ;;
        *) echo "Invalid choice. Going back to student list." ;;
    esac
}

# Function to add a new student
add_student() {
    clear
    echo "Add a New Student:"
    # Prompt user for student details
    read -p "Enter full name: " full_name
    while [ -z "$full_name" ]; do
        echo "Full name cannot be empty."
        read -p "Enter full name: " full_name
    done

    # Validate phone number (must be numeric)
    while true; do
        read -p "Enter phone number (numbers only): " phone_number
        if [[ "$phone_number" =~ ^[0-9]+$ ]]; then
            break
        else
            echo "Invalid phone number. Please enter numbers only."
        fi
    done

    # Validate date of birth format (YYYY-MM-DD)
    while true; do
        read -p "Enter date of birth (YYYY-MM-DD): " dob
        validate_date "$dob"
        if [ $? -eq 0 ]; then
            break
        fi
    done

    read -p "Enter mother tongue: " mother_tongue
    read -p "Enter blood group: " blood_group
    read -p "Enter mother's name: " mother_name
    read -p "Enter father's name: " father_name
    read -p "Enter nationality: " nationality

    # Formulate the SQL query with only non-null fields
    sql_query="INSERT INTO StudentRecords (full_name, phone_number"
    if [ -n "$dob" ]; then
        sql_query+=", dob"
    fi
    if [ -n "$mother_tongue" ]; then
        sql_query+=", mother_tongue"
    fi
    if [ -n "$blood_group" ]; then
        sql_query+=", blood_group"
    fi
    if [ -n "$mother_name" ]; then
        sql_query+=", mother_name"
    fi
    if [ -n "$father_name" ]; then
        sql_query+=", father_name"
    fi
    if [ -n "$nationality" ]; then
        sql_query+=", nationality"
    fi
    sql_query+=") VALUES ('$full_name', '$phone_number'"
    if [ -n "$dob" ]; then
        sql_query+=",'$dob'"
    fi
    if [ -n "$mother_tongue" ]; then
        sql_query+=",'$mother_tongue'"
    fi
    if [ -n "$blood_group" ]; then
        sql_query+=",'$blood_group'"
    fi
    if [ -n "$mother_name" ]; then
        sql_query+=",'$mother_name'"
    fi
    if [ -n "$father_name" ]; then
        sql_query+=",'$father_name'"
    fi
    if [ -n "$nationality" ]; then
        sql_query+=",'$nationality'"
    fi
    sql_query+=");"

    # Execute the SQL query
    mysql -h "$hostname" -P "$port" -u "$username" -p"$password" "$dbname" -e "$sql_query"
    echo "Student added successfully."
    read -p "Press Enter to continue..."
}

# Function to edit a student
edit_student() {
    clear
    student_id=$1
    echo "Edit Student Details (ID: $student_id):"
    # Fetch current details of the student
    current_details=$(mysql -h "$hostname" -P "$port" -u "$username" -p"$password" "$dbname" -se "SELECT * FROM StudentRecords WHERE student_id=$student_id;")
    # Parse current details into variables
    IFS=$'\t' read -r -a details <<< "$current_details"
    current_full_name=${details[1]}
    current_phone_number=${details[2]}
    current_dob=${details[3]}
    current_mother_tongue=${details[4]}
    current_blood_group=${details[5]}
    current_mother_name=${details[6]}
    current_father_name=${details[7]}
    current_nationality=${details[8]}
    
    # Prompt user for new details
    read -p "Enter new full name [$current_full_name]: " new_full_name
    read -p "Enter new phone number [$current_phone_number]: " new_phone_number
    read -p "Enter new date of birth (YYYY-MM-DD) [$current_dob]: " new_dob
    read -p "Enter new mother tongue [$current_mother_tongue]: " new_mother_tongue
    read -p "Enter new blood group [$current_blood_group]: " new_blood_group
    read -p "Enter new mother's name [$current_mother_name]: " new_mother_name
    read -p "Enter new father's name [$current_father_name]: " new_father_name
    read -p "Enter new nationality [$current_nationality]: " new_nationality

    # Formulate the SQL query with only non-null fields
    sql_query="UPDATE StudentRecords SET"
    if [ -n "$new_full_name" ]; then
        sql_query+=" full_name='$new_full_name',"
    fi
    if [ -n "$new_phone_number" ]; then
        sql_query+=" phone_number='$new_phone_number',"
    fi
    if [ -n "$new_dob" ]; then
        sql_query+=" dob='$new_dob',"
    fi
    if [ -n "$new_mother_tongue" ]; then
        sql_query+=" mother_tongue='$new_mother_tongue',"
    fi
    if [ -n "$new_blood_group" ]; then
        sql_query+=" blood_group='$new_blood_group',"
    fi
    if [ -n "$new_mother_name" ]; then
        sql_query+=" mother_name='$new_mother_name',"
    fi
    if [ -n "$new_father_name" ]; then
        sql_query+=" father_name='$new_father_name',"
    fi
    if [ -n "$new_nationality" ]; then
        sql_query+=" nationality='$new_nationality',"
    fi
    # Remove the trailing comma
    sql_query=${sql_query%,}
    sql_query+=" WHERE student_id=$student_id;"

    # Execute the SQL query
    mysql -h "$hostname" -P "$port" -u "$username" -p"$password" "$dbname" -e "$sql_query"
    echo "Student details updated successfully."
    read -p "Press Enter to continue..."
}

# Function to delete a student
delete_student() {
    clear
    echo "Delete a Student:"
    # Prompt user for student ID to delete
    read -p "Enter student ID to delete: " student_id

    # MySQL query to delete student record
    mysql -h "$hostname" -P "$port" -u "$username" -p"$password" "$dbname" -e "DELETE FROM StudentRecords WHERE student_id=$student_id;"
    echo "Student deleted successfully."
    read -p "Press Enter to continue..."
}

# Main function
main() {
    while true; do
        display_menu
        read choice
        case $choice in
            1) view_students ;;
            2) add_student ;;
            3) edit_student_menu ;;
            4) delete_student ;;
            5) echo "Exiting..."; exit ;;
            *) echo "Invalid choice. Please enter a valid option." ;;
        esac
    done
}

# Function to display the edit student menu
edit_student_menu() {
    clear
    echo "Edit a Student:"
    read -p "Enter student ID to edit: " student_id
    student_exists=$(mysql -h "$hostname" -P "$port" -u "$username" -p"$password" "$dbname" -se "SELECT COUNT(*) FROM StudentRecords WHERE student_id=$student_id;")
    if [ "$student_exists" -eq 1 ]; then
        edit_student "$student_id"
    else
        echo "Invalid student ID. Please enter a valid ID."
        read -p "Press Enter to continue..."
    fi
}

# Call the main function
main
