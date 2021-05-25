mkdir project_tester
unzip $1 -d project_tester >> /dev/null
cd project_tester
gcc main.c -o main
./main
returnCode="$?"
cd ..
rm project_tester/*
rmdir project_tester
exit  $returnCode
