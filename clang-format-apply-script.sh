
find . -name "*.m" | while read -r line; do mv $line $line".f"; clang-format $line".f" > $line; rm $line".f"  ; done

find . -name "*.mm" | while read -r line; do mv $line $line".f"; clang-format $line".f" > $line; rm $line".f"  ; done

find . -name "*.h" | while read -r line; do mv $line $line".f"; clang-format $line".f" > $line; rm $line".f"  ; done