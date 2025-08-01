extensions [palette csv]

globals [upper-end lower-end]

turtles-own [opinion identity ]

to setup
  random-seed seed
  clear-all
  set lower-end -1
  set upper-end 1
  let n-bins 11 ; Likert-scale of the item in question

  file-close-all

  if-else ( create-random-agents ) [
    create-turtles 100 [
      set opinion min list 1 ( max list -1 random-normal group-A-initial-mean group-A-std )
          set identity  "left"
          set shape "circle"
          set size 1
          move-to one-of patches
        ]
    create-turtles 100 [
      set opinion  min list 1 ( max list -1 random-normal group-B-initial-mean group-B-std )
          set identity "right"
          set shape "square"
          set size 1
          ;;move-to one-of patches
       ]
  ]  [
    let fname ( word "datasets/ess11_austria_imueclt_n200_seed" seed ".csv" )
    file-open fname ; open the file with the turtle data
    let n 0
    ; We'll read all the data in a single loop
    while [ not file-at-end? ] [
      ; here the CSV extension grabs a single line and puts the read data in a list
      let data csv:from-row file-read-line
      if (n != 0)[
        ; now we can use that list to create a turtle with the saved properties
        create-turtles 1 [
          set opinion (item 0 data) - 1 / n-bins + ( upper-end - lower-end ) / n-bins * (random-float 1)
          ;;set opinion read-from-string opinion
          set identity  item 2 data
          set shape ifelse-value( identity = "left") [ "circle" ][ifelse-value( identity = "middle left") ["star"][ifelse-value( identity = "none") ["x"] [ifelse-value( identity = "middle right") ["triangle"] [ ifelse-value( identity = "right") ["square"]["line"] ]]]]
          set size 1
          ;;move-to one-of patches
        ]
      ]
      set n n + 1
    ]
  ]

  ;; CREATE NETWORK
  setup-caveman-network-by-identity
  maslov-sneppen-rewire ( 1 - homophily )
  layout-nodes

  update-colors ;;color represents opinion
  reset-ticks

end


to setup-caveman-network-by-identity
  let identity-groups remove-duplicates [identity] of turtles
  let group-turtles []

  ;; ids of agents in each group
  foreach identity-groups [ id ->
    set group-turtles lput (turtles with [identity = id]) group-turtles
  ]

  ;; Fully connect agents within each group ( = cave)
  foreach group-turtles [ group ->
    ask group [
      ask other group [
        if not link-neighbor? myself [
          create-link-with myself
        ]
      ]
    ]
  ]

end


to maslov-sneppen-rewire [h]
  let all-links links
  let n-rewires count all-links

  repeat n-rewires [
    if (random-float 1 < h) [
      let edge1 one-of all-links
      let edge2 one-of all-links
      if (edge1 != edge2) [
        let a1 [end1] of edge1
        let b1 [end2] of edge1
        let a2 [end1] of edge2
        let b2 [end2] of edge2

        if (a1 != b2 and a2 != b1 and
            not link-exists? a1 b2 and
            not link-exists? a2 b1 and
            a1 != b1 and a2 != b2 and
            a1 != a2 and b1 != b2) [
          ask edge1 [ die ]
          ask edge2 [ die ]
          ask a1 [ create-link-with b2 ]
          ask a2 [ create-link-with b1 ]
        ]
      ]
    ]
  ]
end

to layout-nodes
  let n count turtles
  let radius 17  ;; adjust this to make the circle bigger or smaller

  ask turtles [
    let angle (who * 360 / n)
    let r radius + min list 1.9 random-normal 0 2  ;; radius with some noise
    let x r * cos angle
    let y r * sin angle
    setxy x y
    set heading angle
  ]

  ask links [
    if-else (random-float 1.0) < 0.10 [
      show-link
    ] [
      hide-link
    ]
  ]
end




to-report link-exists? [a b]
  report a != b and member? b [link-neighbors] of a
end




to go
  ;; a random agent chooses another agent for a potential interaction
  ask one-of turtles [
    let x1 opinion ;;my opinion
    ;;let other-turtle one-of other turtles ;;choose interaction partner at random
    ;;let within-group ( identity = [identity] of other-turtle ) ;; True if turtle and other-turtle have same identity.
    let receiver one-of link-neighbors
    if receiver != nobody [

      let within-group  ( identity = [identity] of receiver  )

      let x2 [opinion] of receiver  ;;other guy's opinion

      ;; Noise
      let current-sigma-ambiguity ifelse-value (identity-dependent-noise) [ifelse-value( within-group ) [sigma-ambiguity-within-group] [sigma-ambiguity]] [sigma-ambiguity]
      let current-sigma-adaptation ifelse-value (identity-dependent-noise) [ifelse-value( within-group ) [sigma-adaptation-within-group] [sigma-adaptation]] [sigma-adaptation]
      let current-sigma-selectivity ifelse-value (identity-dependent-noise) [ifelse-value( within-group ) [sigma-selectivity-within-group] [sigma-selectivity]] [sigma-selectivity]

      ;; message
      let m1 -999
      while [m1 > upper-end or m1 < lower-end]
      [ set m1 x1 + random-normal 0 current-sigma-ambiguity   ]  ;; add ambiguity until m1 within bounds

      ;; SELECTION
      let successful-interaction 0
      if (abs (x2 - m1) < confidence-bound + random-normal 0 current-sigma-selectivity) [
        set successful-interaction 1
      ]

      if (successful-interaction != 0) [
        ;; change receiver's opinion
        let x2-new-mean (x2 + successful-interaction * learning-rate * (m1 - x2))
        let x2-new -999
        while [x2-new > upper-end  or x2-new < lower-end]
        [ set x2-new x2-new-mean + random-normal 0 current-sigma-adaptation ]
        ask receiver [ set opinion x2-new]
      ]
    ]
  ]
  update-colors
  tick
end


;;shade each agent between black (opinion = -1) and white (opinion = 1)
to update-colors
  ask turtles [
    set color ifelse-value (opinion < 0.) [94 - (lower-end - opinion) * 5][ 19 - (opinion) * 5]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
25
95
443
514
-1
-1
10.0
1
10
1
1
1
0
0
0
1
-20
20
-20
20
0
0
1
ticks
30.0

SLIDER
985
90
1165
123
sigma-ambiguity-within-group
sigma-ambiguity-within-group
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
600
265
775
298
confidence-bound
confidence-bound
0
1
0.25
0.01
1
NIL
HORIZONTAL

SLIDER
600
325
775
358
learning-rate
learning-rate
0
0.5
0.5
0.05
1
NIL
HORIZONTAL

BUTTON
29
23
96
56
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
144
26
207
59
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

PLOT
655
435
865
609
Variance
ticks
varaince
0.0
1.0
0.0
0.5
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot standard-deviation [opinion] of turtles"

PLOT
466
432
646
610
mean
ticks
mean
0.0
1.0
-1.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -2674135 true "" "plot mean [opinion] of turtles"

SLIDER
785
145
957
178
sigma-adaptation
sigma-adaptation
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
785
200
957
233
sigma-selectivity
sigma-selectivity
0
1
0.0
0.01
1
NIL
HORIZONTAL

PLOT
1220
10
1660
130
histogram all
opinion
frequency
-1.01
1.01
0.0
100.0
false
false
"set-histogram-num-bars 10\nset-plot-y-range 0 count turtles\nset-plot-x-range (lower-end - 0.02) (upper-end + 0.02)" ""
PENS
"default" 0.2 1 -16777216 false "" "histogram [opinion] of turtles"

TEXTBOX
480
50
721
76
Different types of Noise\n
20
0.0
1

TEXTBOX
482
89
780
295
Ambiguity noise strength\n(affects message)\n\nAdaptation noise strength\n(affects receiver opinion **after** social influence)\n\nSelectivity noise strength\n(affects receiver's confidence bound)\n
12
0.0
1

SLIDER
785
90
960
123
sigma-ambiguity
sigma-ambiguity
0
1
0.0
0.01
1
NIL
HORIZONTAL

PLOT
1220
650
1665
770
histogram-identity
opinion
frequency
-1.02
1.02
0.0
50.0
false
false
"set-histogram-num-bars 5\nset-plot-y-range 0 (count turtles / 4)\nset-plot-x-range (lower-end - 0.02) (upper-end + 0.02)" ""
PENS
"group_mr" 0.4 1 -5516827 true "" "histogram [opinion] of turtles with [identity = \"middle right\"]"
"group_l" 0.4 1 -5298144 true "" "histogram [opinion] of turtles with [identity = \"left\"]"
"group_ml" 0.4 1 -1069655 true "" "histogram [opinion] of turtles with [identity = \"middle left\"]"
"group_r" 0.4 1 -14454117 true "" "histogram [opinion] of turtles with [identity = \"right\"]"
"none" 0.4 1 -7500403 true "" "histogram [opinion] of turtles with [identity = \"none\"]"

MONITOR
1670
565
1720
610
Left
count turtles with [ identity = \"left\" ]
17
1
11

MONITOR
1665
440
1743
485
Middle left
count turtles with [ identity = \"middle left\" ]
17
1
11

MONITOR
1665
290
1753
335
middle right
count turtles with [ identity = \"middle right\" ]
17
1
11

MONITOR
1665
170
1722
215
right
count turtles with [ identity = \"right\" ]
17
1
11

PLOT
1220
130
1660
250
Histogram Right
opinion
frequency
-1.02
1.02
0.0
10.0
false
false
"set-histogram-num-bars 5\nset-plot-y-range 0 (count turtles / 4)\nset-plot-x-range (lower-end - 0.02) (upper-end + 0.02)" ""
PENS
"default" 0.4 1 -14454117 true "" "histogram [opinion] of turtles with [identity = \"right\"]"

PLOT
1220
250
1660
390
Histogram Middle Right
opinion
frequency
-1.02
1.02
0.0
20.0
false
false
"set-histogram-num-bars 5\nset-plot-y-range 0 (count turtles / 4)\nset-plot-x-range (lower-end - 0.02) (upper-end + 0.02)\n" ""
PENS
"default" 0.4 1 -5516827 true "" "histogram [opinion] of turtles with [identity = \"middle right\"]"

PLOT
1220
525
1665
645
Histogram Left
opinion
frequency
-1.02
1.02
0.0
10.0
false
false
"set-histogram-num-bars 5\nset-plot-y-range 0 (count turtles / 4)\nset-plot-x-range (lower-end - 0.02) (upper-end + 0.02)" ""
PENS
"default" 0.4 1 -5298144 true "" "histogram [opinion] of turtles with [identity = \"left\"]"

PLOT
1220
400
1660
520
Histogram Middle Left
opinion
frequency
-1.02
1.02
0.0
30.0
false
false
"set-histogram-num-bars 5\nset-plot-y-range 0 (count turtles / 4)\nset-plot-x-range (lower-end - 0.02) (upper-end + 0.02)" ""
PENS
"default" 0.4 1 -1069655 true "" "histogram [opinion] of turtles with [identity = \"middle left\"]"

SLIDER
600
380
775
413
homophily
homophily
0
1
0.73
0.01
1
NIL
HORIZONTAL

SWITCH
980
40
1170
73
identity-dependent-noise
identity-dependent-noise
0
1
-1000

INPUTBOX
265
20
422
80
seed
48.0
1
0
Number

SLIDER
985
145
1165
178
sigma-adaptation-within-group
sigma-adaptation-within-group
0
1
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
985
200
1165
233
sigma-selectivity-within-group
sigma-selectivity-within-group
0
1
0.0
0.01
1
NIL
HORIZONTAL

SWITCH
110
665
312
698
create-random-agents
create-random-agents
1
1
-1000

SLIDER
330
665
512
698
group-A-initial-mean
group-A-initial-mean
-1
1
-0.5
0.01
1
NIL
HORIZONTAL

SLIDER
330
705
512
738
group-B-initial-mean
group-B-initial-mean
-1
1
0.5
0.01
1
NIL
HORIZONTAL

SLIDER
520
665
692
698
group-A-std
group-A-std
0
2
0.1
0.01
1
NIL
HORIZONTAL

SLIDER
520
705
692
738
group-B-std
group-B-std
0
2
0.1
0.01
1
NIL
HORIZONTAL

TEXTBOX
95
520
415
551
NOTE: We are only showing 10 % of all links.
12
0.0
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="1000" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="100000"/>
    <metric>standard-deviation [opinion] of turtles</metric>
    <metric>mean [opinion] of turtles</metric>
    <enumeratedValueSet variable="sigma-ambiguity">
      <value value="0"/>
      <value value="0.025"/>
      <value value="0.05"/>
      <value value="0.075"/>
      <value value="0.1"/>
      <value value="0.125"/>
      <value value="0.15"/>
      <value value="0.175"/>
      <value value="0.2"/>
      <value value="0.225"/>
      <value value="0.25"/>
      <value value="0.275"/>
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="confidence-threshold">
      <value value="0"/>
      <value value="0.025"/>
      <value value="0.05"/>
      <value value="0.075"/>
      <value value="0.1"/>
      <value value="0.125"/>
      <value value="0.15"/>
      <value value="0.175"/>
      <value value="0.2"/>
      <value value="0.225"/>
      <value value="0.25"/>
      <value value="0.275"/>
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate">
      <value value="0.5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="quick-experiment" repetitions="20" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="10000"/>
    <metric>standard-deviation [opinion] of turtles</metric>
    <metric>mean [opinion] of turtles</metric>
    <enumeratedValueSet variable="sigma-ambiguity">
      <value value="0.05"/>
      <value value="0.15"/>
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="confidence-threshold">
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate">
      <value value="0.5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="run sigma-ambiguities" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="100000"/>
    <metric>standard-deviation [opinion] of turtles</metric>
    <metric>mean [opinion] of turtles</metric>
    <metric>standard-deviation [opinion] of turtles with [identity = "right"]</metric>
    <metric>standard-deviation [opinion] of turtles with [identity = "middle right"]</metric>
    <metric>standard-deviation [opinion] of turtles with [identity = "middle left"]</metric>
    <metric>standard-deviation [opinion] of turtles with [identity = "left"]</metric>
    <metric>mean [opinion] of turtles with [identity = "right"]</metric>
    <metric>mean [opinion] of turtles with [identity = "middle right"]</metric>
    <metric>mean[opinion] of turtles with [identity = "middle left"]</metric>
    <metric>mean [opinion] of turtles with [identity = "left"]</metric>
    <runMetricsCondition>( ticks mod 1000 ) = 0</runMetricsCondition>
    <enumeratedValueSet variable="sigma-ambiguity-within-group">
      <value value="0.05"/>
      <value value="0.15"/>
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sigma-ambiguity-between-group">
      <value value="0.05"/>
      <value value="0.15"/>
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="confidence-threshold-converge">
      <value value="0.2"/>
      <value value="0.3"/>
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-exogenous">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sigma-selectivity">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sigma-exogenous">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sigma-adaptation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homophily">
      <value value="0"/>
      <value value="0.1"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fname">
      <value value="&quot;datasets/ess11_austria_imueclt_n200_seed1.csv&quot;"/>
      <value value="&quot;datasets/ess11_austria_imueclt_n200_seed2.csv&quot;"/>
      <value value="&quot;datasets/ess11_austria_imueclt_n200_seed3.csv&quot;"/>
      <value value="&quot;datasets/ess11_austria_imueclt_n200_seed4.csv&quot;"/>
      <value value="&quot;datasets/ess11_austria_imueclt_n200_seed5.csv&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="run sigma-ambiguities (short)" repetitions="2" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="100000"/>
    <metric>standard-deviation [opinion] of turtles</metric>
    <metric>mean [opinion] of turtles</metric>
    <metric>standard-deviation [opinion] of turtles with [identity = "right"]</metric>
    <metric>standard-deviation [opinion] of turtles with [identity = "middle right"]</metric>
    <metric>standard-deviation [opinion] of turtles with [identity = "middle left"]</metric>
    <metric>standard-deviation [opinion] of turtles with [identity = "left"]</metric>
    <metric>mean [opinion] of turtles with [identity = "right"]</metric>
    <metric>mean [opinion] of turtles with [identity = "middle right"]</metric>
    <metric>mean[opinion] of turtles with [identity = "middle left"]</metric>
    <metric>mean [opinion] of turtles with [identity = "left"]</metric>
    <runMetricsCondition>( ticks mod 1000 ) = 0</runMetricsCondition>
    <enumeratedValueSet variable="sigma-ambiguity-within-group">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sigma-ambiguity-between-group">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="confidence-threshold-converge">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-exogenous">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sigma-selectivity">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sigma-exogenous">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sigma-adaptation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homophily">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fname">
      <value value="&quot;datasets/ess11_austria_imueclt_n200_seed1.csv&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="run sigma-ambiguities (long)" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="100000"/>
    <metric>standard-deviation [opinion] of turtles</metric>
    <metric>mean [opinion] of turtles</metric>
    <metric>mean [abs opinion] of turtles</metric>
    <metric>standard-deviation [opinion] of turtles with [identity = "right"]</metric>
    <metric>standard-deviation [opinion] of turtles with [identity = "middle right"]</metric>
    <metric>standard-deviation [opinion] of turtles with [identity = "middle left"]</metric>
    <metric>standard-deviation [opinion] of turtles with [identity = "left"]</metric>
    <metric>mean [opinion] of turtles with [identity = "right"]</metric>
    <metric>mean [opinion] of turtles with [identity = "middle right"]</metric>
    <metric>mean [opinion] of turtles with [identity = "middle left"]</metric>
    <metric>mean [opinion] of turtles with [identity = "left"]</metric>
    <metric>mean [abs opinion] of turtles with [identity = "right"]</metric>
    <metric>mean [abs opinion] of turtles with [identity = "middle right"]</metric>
    <metric>mean [abs opinion] of turtles with [identity = "middle left"]</metric>
    <metric>mean [abs opinion] of turtles with [identity = "left"]</metric>
    <runMetricsCondition>( ticks mod 1000 ) = 0</runMetricsCondition>
    <enumeratedValueSet variable="sigma-ambiguity-within-group">
      <value value="0"/>
      <value value="0.05"/>
      <value value="0.1"/>
      <value value="0.15"/>
      <value value="0.2"/>
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sigma-ambiguity-between-group">
      <value value="0"/>
      <value value="0.05"/>
      <value value="0.1"/>
      <value value="0.15"/>
      <value value="0.2"/>
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="confidence-threshold-converge">
      <value value="0.2"/>
      <value value="0.3"/>
      <value value="0.4"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-exogenous">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sigma-selectivity">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sigma-exogenous">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sigma-adaptation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homophily">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fname">
      <value value="&quot;datasets/ess11_austria_imueclt_n200_seed0.csv&quot;"/>
      <value value="&quot;datasets/ess11_austria_imueclt_n200_seed1.csv&quot;"/>
      <value value="&quot;datasets/ess11_austria_imueclt_n200_seed2.csv&quot;"/>
      <value value="&quot;datasets/ess11_austria_imueclt_n200_seed3.csv&quot;"/>
      <value value="&quot;datasets/ess11_austria_imueclt_n200_seed4.csv&quot;"/>
      <value value="&quot;datasets/ess11_austria_imueclt_n200_seed5.csv&quot;"/>
      <value value="&quot;datasets/ess11_austria_imueclt_n200_seed6.csv&quot;"/>
      <value value="&quot;datasets/ess11_austria_imueclt_n200_seed7.csv&quot;"/>
      <value value="&quot;datasets/ess11_austria_imueclt_n200_seed8.csv&quot;"/>
      <value value="&quot;datasets/ess11_austria_imueclt_n200_seed9.csv&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="run noise combos (long)" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="100000"/>
    <metric>standard-deviation [opinion] of turtles</metric>
    <metric>mean [opinion] of turtles</metric>
    <metric>mean [abs opinion] of turtles</metric>
    <metric>standard-deviation [opinion] of turtles with [identity = "right"]</metric>
    <metric>standard-deviation [opinion] of turtles with [identity = "middle right"]</metric>
    <metric>standard-deviation [opinion] of turtles with [identity = "middle left"]</metric>
    <metric>standard-deviation [opinion] of turtles with [identity = "left"]</metric>
    <metric>mean [opinion] of turtles with [identity = "right"]</metric>
    <metric>mean [opinion] of turtles with [identity = "middle right"]</metric>
    <metric>mean [opinion] of turtles with [identity = "middle left"]</metric>
    <metric>mean [opinion] of turtles with [identity = "left"]</metric>
    <metric>mean [abs opinion] of turtles with [identity = "right"]</metric>
    <metric>mean [abs opinion] of turtles with [identity = "middle right"]</metric>
    <metric>mean [abs opinion] of turtles with [identity = "middle left"]</metric>
    <metric>mean [abs opinion] of turtles with [identity = "left"]</metric>
    <runMetricsCondition>( ticks mod 10000 ) = 0</runMetricsCondition>
    <enumeratedValueSet variable="identity-dependent-noise">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sigma-ambiguity-within-group">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sigma-ambiguity">
      <value value="0"/>
      <value value="0.05"/>
      <value value="0.1"/>
      <value value="0.15"/>
      <value value="0.2"/>
      <value value="0.25"/>
      <value value="0.3"/>
      <value value="0.35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="confidence-bound">
      <value value="0.3"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-exogenous">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sigma-selectivity">
      <value value="0"/>
      <value value="0.05"/>
      <value value="0.1"/>
      <value value="0.15"/>
      <value value="0.2"/>
      <value value="0.25"/>
      <value value="0.3"/>
      <value value="0.35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sigma-exogenous">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sigma-selectivity-within-group">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sigma-adaptation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sigma-adaptation-within-group">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homophily">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seed">
      <value value="0"/>
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
      <value value="7"/>
      <value value="8"/>
      <value value="9"/>
      <value value="10"/>
      <value value="11"/>
      <value value="12"/>
      <value value="13"/>
      <value value="14"/>
      <value value="15"/>
      <value value="16"/>
      <value value="17"/>
      <value value="18"/>
      <value value="19"/>
      <value value="20"/>
      <value value="21"/>
      <value value="22"/>
      <value value="23"/>
      <value value="24"/>
      <value value="25"/>
      <value value="26"/>
      <value value="27"/>
      <value value="28"/>
      <value value="29"/>
      <value value="30"/>
      <value value="31"/>
      <value value="32"/>
      <value value="33"/>
      <value value="34"/>
      <value value="35"/>
      <value value="36"/>
      <value value="37"/>
      <value value="38"/>
      <value value="39"/>
      <value value="40"/>
      <value value="41"/>
      <value value="42"/>
      <value value="43"/>
      <value value="44"/>
      <value value="45"/>
      <value value="46"/>
      <value value="47"/>
      <value value="48"/>
      <value value="49"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="run baseline" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="100000"/>
    <metric>standard-deviation [opinion] of turtles</metric>
    <metric>mean [opinion] of turtles</metric>
    <metric>mean [abs opinion] of turtles</metric>
    <metric>standard-deviation [opinion] of turtles with [identity = "right"]</metric>
    <metric>standard-deviation [opinion] of turtles with [identity = "middle right"]</metric>
    <metric>standard-deviation [opinion] of turtles with [identity = "middle left"]</metric>
    <metric>standard-deviation [opinion] of turtles with [identity = "left"]</metric>
    <metric>mean [opinion] of turtles with [identity = "right"]</metric>
    <metric>mean [opinion] of turtles with [identity = "middle right"]</metric>
    <metric>mean [opinion] of turtles with [identity = "middle left"]</metric>
    <metric>mean [opinion] of turtles with [identity = "left"]</metric>
    <metric>mean [abs opinion] of turtles with [identity = "right"]</metric>
    <metric>mean [abs opinion] of turtles with [identity = "middle right"]</metric>
    <metric>mean [abs opinion] of turtles with [identity = "middle left"]</metric>
    <metric>mean [abs opinion] of turtles with [identity = "left"]</metric>
    <runMetricsCondition>( ticks mod 10000 ) = 0</runMetricsCondition>
    <enumeratedValueSet variable="identity-dependent-noise">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sigma-ambiguity-within-group">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sigma-ambiguity">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="confidence-bound">
      <value value="0.2"/>
      <value value="0.3"/>
      <value value="0.4"/>
      <value value="0.5"/>
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-exogenous">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sigma-selectivity">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sigma-exogenous">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sigma-selectivity-within-group">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sigma-adaptation">
      <value value="0"/>
      <value value="0.05"/>
      <value value="0.1"/>
      <value value="0.15"/>
      <value value="0.2"/>
      <value value="0.25"/>
      <value value="0.3"/>
      <value value="0.35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sigma-adaptation-within-group">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homophily">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seed">
      <value value="0"/>
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
      <value value="7"/>
      <value value="8"/>
      <value value="9"/>
      <value value="10"/>
      <value value="11"/>
      <value value="12"/>
      <value value="13"/>
      <value value="14"/>
      <value value="15"/>
      <value value="16"/>
      <value value="17"/>
      <value value="18"/>
      <value value="19"/>
      <value value="20"/>
      <value value="21"/>
      <value value="22"/>
      <value value="23"/>
      <value value="24"/>
      <value value="25"/>
      <value value="26"/>
      <value value="27"/>
      <value value="28"/>
      <value value="29"/>
      <value value="30"/>
      <value value="31"/>
      <value value="32"/>
      <value value="33"/>
      <value value="34"/>
      <value value="35"/>
      <value value="36"/>
      <value value="37"/>
      <value value="38"/>
      <value value="39"/>
      <value value="40"/>
      <value value="41"/>
      <value value="42"/>
      <value value="43"/>
      <value value="44"/>
      <value value="45"/>
      <value value="46"/>
      <value value="47"/>
      <value value="48"/>
      <value value="49"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="run in-out noise" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="100000"/>
    <metric>standard-deviation [opinion] of turtles</metric>
    <metric>mean [opinion] of turtles</metric>
    <metric>mean [abs opinion] of turtles</metric>
    <metric>standard-deviation [opinion] of turtles with [identity = "right"]</metric>
    <metric>standard-deviation [opinion] of turtles with [identity = "middle right"]</metric>
    <metric>standard-deviation [opinion] of turtles with [identity = "middle left"]</metric>
    <metric>standard-deviation [opinion] of turtles with [identity = "left"]</metric>
    <metric>mean [opinion] of turtles with [identity = "right"]</metric>
    <metric>mean [opinion] of turtles with [identity = "middle right"]</metric>
    <metric>mean [opinion] of turtles with [identity = "middle left"]</metric>
    <metric>mean [opinion] of turtles with [identity = "left"]</metric>
    <metric>mean [abs opinion] of turtles with [identity = "right"]</metric>
    <metric>mean [abs opinion] of turtles with [identity = "middle right"]</metric>
    <metric>mean [abs opinion] of turtles with [identity = "middle left"]</metric>
    <metric>mean [abs opinion] of turtles with [identity = "left"]</metric>
    <runMetricsCondition>( ticks mod 100000 ) = 0</runMetricsCondition>
    <enumeratedValueSet variable="identity-dependent-noise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sigma-ambiguity-within-group">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sigma-ambiguity">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="confidence-bound">
      <value value="0.3"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-exogenous">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sigma-selectivity">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sigma-exogenous">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sigma-selectivity-within-group">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sigma-adaptation">
      <value value="0"/>
      <value value="0.05"/>
      <value value="0.1"/>
      <value value="0.15"/>
      <value value="0.2"/>
      <value value="0.25"/>
      <value value="0.3"/>
      <value value="0.35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sigma-adaptation-within-group">
      <value value="0"/>
      <value value="0.05"/>
      <value value="0.1"/>
      <value value="0.15"/>
      <value value="0.2"/>
      <value value="0.25"/>
      <value value="0.3"/>
      <value value="0.35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homophily">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seed">
      <value value="0"/>
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
      <value value="7"/>
      <value value="8"/>
      <value value="9"/>
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="run in-out noise (shorter)" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="100000"/>
    <metric>standard-deviation [opinion] of turtles</metric>
    <metric>mean [opinion] of turtles</metric>
    <metric>mean [abs opinion] of turtles</metric>
    <metric>standard-deviation [opinion] of turtles with [identity = "right"]</metric>
    <metric>standard-deviation [opinion] of turtles with [identity = "middle right"]</metric>
    <metric>standard-deviation [opinion] of turtles with [identity = "middle left"]</metric>
    <metric>standard-deviation [opinion] of turtles with [identity = "left"]</metric>
    <metric>mean [opinion] of turtles with [identity = "right"]</metric>
    <metric>mean [opinion] of turtles with [identity = "middle right"]</metric>
    <metric>mean [opinion] of turtles with [identity = "middle left"]</metric>
    <metric>mean [opinion] of turtles with [identity = "left"]</metric>
    <metric>mean [abs opinion] of turtles with [identity = "right"]</metric>
    <metric>mean [abs opinion] of turtles with [identity = "middle right"]</metric>
    <metric>mean [abs opinion] of turtles with [identity = "middle left"]</metric>
    <metric>mean [abs opinion] of turtles with [identity = "left"]</metric>
    <runMetricsCondition>( ticks mod 100000 ) = 0</runMetricsCondition>
    <enumeratedValueSet variable="identity-dependent-noise">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sigma-ambiguity-within-group">
      <value value="0"/>
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sigma-ambiguity">
      <value value="0"/>
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="confidence-bound">
      <value value="0.3"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="learning-rate">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-exogenous">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sigma-selectivity">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sigma-exogenous">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sigma-selectivity-within-group">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sigma-adaptation">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sigma-adaptation-within-group">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="homophily">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seed">
      <value value="0"/>
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
      <value value="7"/>
      <value value="8"/>
      <value value="9"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
1
@#$#@#$#@
