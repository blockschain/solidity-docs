FILES=docs/*.rst
for f in $FILES
# for f in $1
do
  filename="${f%.*}"
  echo "Converting $f to $filename.md"
  `pandoc $f -f rst -t markdown -o $filename.md`
  rm $f
done
