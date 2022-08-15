5 rem A quick test of how this works!
10 gosub 1000
20 for y=0 to 7
30  for x=0 to 7
40   gosub 1200
45   gosub 1100
50 next x,y

60 for y=7 to 0 step -1
70  for x=7 to 0 step -1
80   gosub 1300
85  gosub 1100
90 next x,y
100 goto 10


990 rem Initialise data
1000 dim pixels[7]
1040 def fngetpixel(x,y)=pixels[y] and (2^x)
1050 return

1090 rem Update display
1100 for r=0 to 7
1110  out 0,2^r:out 2,pixels[r]
1120 next
1130 return

1190 rem Write pixel at x,y
1200 pixels[y]=pixels[y] or (2^(7-x))
1210 return

1290 rem clear pixel at x,y
1300 pixels[y]=pixels[y] and ((2^(7-x)) xor 255)
1310 return

