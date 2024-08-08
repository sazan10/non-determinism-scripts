#!/bin/bash

# Input log file containing the data race warnings
base_path_for_logs=$1
# Output CSV file

# Write the CSV header
# project_name,branch,run,
# Read the input log file line by line
for project in $(ls $base_path_for_logs)
do
    for txt_file in $(ls $base_path_for_logs/$project)
    do
            # if extension is not txt, then continue
        if [[ $txt_file != *.txt ]]; then
            continue
        fi
        echo "Write1 Function,Read1 Function, Thread1 Name, Location1, Write2 Function,  Read2 Function, Thread2 Name, Location2, Byte Size, Allocation Type, Allocation details" >  "$base_path_for_logs/$project/$txt_file.csv"

        while IFS= read -r line
        do
            # Check for the beginning of a data race warning
            if [[ "$line" == *"WARNING: ThreadSanitizer: data race"* ]]; then
                write1_function=""
                read1_function=""
                thread1_name=""
                write2_function=""
                read2_function=""
                thread2_name=""
                byte_size=""
                mode1=""
                mode2=""      
                allocation_type=""
                allocation_details=""   
                location1=""
                location2=""   
                # Read subsequent lines to extract relevant information
                while IFS= read -r inner_line
                do
                    # Extract byte size and mode
                    if [[ "${inner_line,,}" == *"write of size"* &&  "${inner_line,,}" != *"previous write of size"* ]]; then
                        byte_size=$(echo "$inner_line" | grep -oiP 'write of size \K[0-9]+')
                        thread1_name=$(echo "$inner_line" | grep -oiP 'by (thread T[0-9]|main thread)')
                        check_hash=false
                        while IFS= read -r inner_line2
                        do
                            if [[ "$inner_line2" == *"#0 "* ]]; then
                            location1=$(echo "$inner_line2" | awk '{print $4}')
                            fi                        
                            # if [[ "$inner_line2" == *"#0 "* ]]; then
                            #     write1_function=$(echo "$inner_line2" | awk '{print $3}')
                            #     location1=$(echo "$inner_line2" | awk '{print $4}')
                            #     break
                            # fi
                            if [[ "$inner_line2" =~ (#[0-9]+) ]]; then
                                # write1_function=$(echo "$inner_line2" | awk '{print $3}')
                                new_function=$(echo "$inner_line2" | awk '{print $3}')
                                new_location=$(echo "$inner_line2" | awk '{print $4}')
                                write1_function="$write1_function$new_function|$new_location|"
                                check_hash=true
                            elif $check_hash; then
                                break
                            fi
                        done < <(tail -n +$(grep -n -m 1 "$inner_line" "$base_path_for_logs/$project/$txt_file" | cut -d: -f1) "$base_path_for_logs/$project/$txt_file")    
                    elif [[ "${inner_line,,}" == *"read of size"* &&  "${inner_line,,}" != *"previous read of size"* ]]; then
                        byte_size=$(echo "$inner_line" | grep -oiP 'read of size \K[0-9]+')
                        thread1_name=$(echo "$inner_line" | grep -oiP 'by (thread T[0-9]|main thread)')
                        check_hash=false
                        while IFS= read -r inner_line2
                        do
                            if [[ "$inner_line2" == *"#0 "* ]]; then
                            location1=$(echo "$inner_line2" | awk '{print $4}')
                            fi                        
                            # if [[ "$inner_line2" == *"#0 "* ]]; then
                            #     read1_function=$(echo "$inner_line2" | awk '{print $3}')
                            #     location1=$(echo "$inner_line2" | awk '{print $4}')
                            #     break
                            # fi
                        if [[ "$inner_line2" =~ (#[0-9]+) ]]; then
                            # write1_function=$(echo "$inner_line2" | awk '{print $3}')
                            new_function=$(echo "$inner_line2" | awk '{print $3}')
                            # read1_function="$read1_function$new_function|"
                            new_location=$(echo "$inner_line2" | awk '{print $4}')
                            read1_function="$read1_function$new_function|$new_location|"
                            # echo "read1"
                            # echo $read1_function
                            check_hash=true
                        elif $check_hash; then
                            break
                        fi
                        done < <(tail -n +$(grep -n -m 1 "$inner_line" "$base_path_for_logs/$project/$txt_file" | cut -d: -f1) "$base_path_for_logs/$project/$txt_file")
                    elif [[ "${inner_line,,}" == *"previous read of size"* ]]; then
                        byte_size=$(echo "$inner_line" | grep -oiP 'previous read of size \K[0-9]+')
                        thread2_name=$(echo "$inner_line" | grep -oiP 'by (thread T[0-9]|main thread)')
                        check_hash=false
                        while IFS= read -r inner_line2
                        do
                            if [[ "$inner_line2" == *"#0 "* ]]; then
                            location2=$(echo "$inner_line2" | awk '{print $4}')
                            fi                        
                            # if [[ "$inner_line2" == *"#0 "* ]]; then
                            #     read2_function=$(echo "$inner_line2" | awk '{print $3}')
                            #     location2=$(echo "$inner_line2" | awk '{print $4}')
                            #     break
                            # fi
                        if [[ "$inner_line2" =~ (#[0-9]+) ]]; then
                            # write1_function=$(echo "$inner_line2" | awk '{print $3}')
                            new_function=$(echo "$inner_line2" | awk '{print $3}')
                            # echo "read2"
                            new_location=$(echo "$inner_line2" | awk '{print $4}')
                            read2_function="$read2_function$new_function|$new_location|"
                            # read2_function="$read2_function$new_function|"
                            # echo $read2_function
                            # location2=$(echo "$inner_line2" | awk '{print $4}')
                            check_hash=true
                        elif $check_hash; then
                            break
                        fi
                        done < <(tail -n +$(grep -n -m 1 "$inner_line" "$base_path_for_logs/$project/$txt_file" | cut -d: -f1) "$base_path_for_logs/$project/$txt_file")      
                    elif [[ "${inner_line,,}" == *"previous write of size"* ]]; then
                        byte_size=$(echo "$inner_line" | grep -oiP 'previous write of size \K[0-9]+')
                        thread2_name=$(echo "$inner_line" | grep -oiP 'by (thread T[0-9]|main thread)')
                        check_hash=false
                        while IFS= read -r inner_line2
                        do
                            if [[ "$inner_line2" == *"#0 "* ]]; then
                            location2=$(echo "$inner_line2" | awk '{print $4}')
                            fi                        
                            # if [[ "$inner_line2" == *"#0 "* ]]; then
                            #     write2_function=$(echo "$inner_line2" | awk '{print $3}')
                            #     location2=$(echo "$inner_line2" | awk '{print $4}')
                            #     break
                            # fi
                        if [[ "$inner_line2" =~ (#[0-9]+) ]]; then
                            # write1_function=$(echo "$inner_line2" | awk '{print $3}')
                            new_function=$(echo "$inner_line2" | awk '{print $3}')
                            # echo "write2"
                            # write2_function="$write2_function$new_function|"
                            new_location=$(echo "$inner_line2" | awk '{print $4}')
                            write2_function="$write2_function$new_function|$new_location|"
                            # echo $write2_function
                            # location2=$(echo "$inner_line2" | awk '{print $4}')
                            check_hash=true
                        elif $check_hash; then
                            break
                        fi
                        done < <(tail -n +$(grep -n -m 1 "$inner_line" "$base_path_for_logs/$project/$txt_file" | cut -d: -f1) "$base_path_for_logs/$project/$txt_file")       
                    fi
                    # # Extract write function
                    # if [[ "$inner_line" == *"by main thread"* || "$inner_line" == *"by thread T"* ]]; then
                    #     if [[ "$inner_line" == *"#0 "* ]]; then
                    #         write_function=$(echo "$inner_line" | awk '{print $2}')
                    #     fi
                    # fi

                    # # Extract read function
                    # if [[ "$inner_line" == *"by main thread"* ||  "$inner_line" == *"by thread T"* ]]; then
                    #     if [[ "$inner_line" == *"#0 "* ]]; then
                    #         read_function=$(echo "$inner_line" | awk '{print $2}')
                    #     fi
                    # fi
                    
                    # Break out of inner loop on the next warning or EOF
                    if [[ "${inner_line,,}" == *"location is"*  ]]; then
                        allocation_type=$(echo "$inner_line" | grep -oiP 'location is.*')
                        while IFS= read -r inner_line2
                        do
                            if [[ $(echo "$inner_line" | awk '{print $4}') == "global" ]]; then
                                break
                            elif [[ "$inner_line2" == *"#0 "* ]]; then
                                allocation_details=$(echo "$inner_line2" | awk '{print $3}')
                                # echo $inner_line
                                break
                            fi
                        done < <(tail -n +$(grep -n -m 1 "$inner_line" "$base_path_for_logs/$project/$txt_file" | cut -d: -f1) "$base_path_for_logs/$project/$txt_file")

                    fi       
                    if [[ "$inner_line" == *"SUMMARY: ThreadSanitizer: data race"* || -z "$inner_line" ]]; then
                        break
                    fi
                done < <(tail -n +$(grep -n -m 1 "$line" "$base_path_for_logs/$project/$txt_file" | cut -d: -f1) "$base_path_for_logs/$project/$txt_file")

                # Append the extracted data to the CSV file
            echo "\"$write1_function\",\"$read1_function\",\"$thread1_name\",\"$location1\",\"$write2_function\",\"$read2_function\",\"$thread2_name\",\"$location2\",\"$byte_size\",\"$allocation_type\",\"$allocation_details\"" >> "$base_path_for_logs/$project/$txt_file.csv"
            # echo "$write1_function,$read1_function,$thread1_name,$location1,$write2_function,$read2_function, $thread2_name,$location2,$byte_size, $allocation_type, $allocation_details" >> "$base_path_for_logs/$project/$txt_file.csv"
            fi
        done < "$base_path_for_logs/$project/$txt_file"
    done
done
echo "Data race report generated in $output_file"
