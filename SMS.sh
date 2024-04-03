#!/bin/bash

# Database connection details
hostname="Localhost"
port="3306"
username="demo_aash"
password="********"
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

# Function to view all students
view_students() {
    clear
    echo "List of Students:"
    # MySQL query to fetch all student records
    mysql -h "$hostname" -P "$port" -u "$username" -p"$password" "$dbname" -e "SELECT * FROM StudentRecords;"
    read -p "Press Enter to continue..."
}

# Function to add a new student
add_student() {
    clear
    echo "Add a New Student:"
    # Prompt user for student details
    read -p "Enter full name: " full_name
    read -p "Enter phone number: " phone_number
    # Similar prompts for other details

    # MySQL query to insert new student record
    mysql -h "$hostname" -P "$port" -u "$username" -p"$password" "$dbname" -e "INSERT INTO StudentRecords (full_name, phone_number) VALUES ('$full_name', '$phone_number');"
    echo "Student added successfully."
    read -p "Press Enter to continue..."
}

# Function to edit a student
edit_student() {
    clear
    echo "Edit a Student:"
    # Prompt user for student ID to edit
    read -p "Enter student ID to edit: " student_id
    # Prompt user for new details
    read -p "Enter new full name: " new_full_name
    read -p "Enter new phone number: " new_phone_number
    # Similar prompts for other details

    # MySQL query to update student record
    mysql -h "$hostname" -P "$port" -u "$username" -p"$password" "$dbname" -e "UPDATE StudentRecords SET full_name='$new_full_name', phone_number='$new_phone_number' WHERE student_id=$student_id;"
    echo "Student updated successfully."
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
            3) edit_student ;;
            4) delete_student ;;
            5) echo "Exiting..."; exit ;;
            *) echo "Invalid choice. Please enter a valid option." ;;
        esac
    done
}

# Call the main function
main
