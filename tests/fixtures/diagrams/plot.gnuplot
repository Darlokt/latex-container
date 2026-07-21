set terminal pdfcairo enhanced color
set output output
set title "Reproducible result"
set xlabel "x"
set ylabel "x squared"
plot x*x title "x^2" with lines
