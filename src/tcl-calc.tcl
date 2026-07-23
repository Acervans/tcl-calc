#!/usr/bin/env wish
catch {console hide}

# Setup UI Window
wm title . "Tcl Calculator"
wm geometry . "650x400"
wm resizable . 0 0
. configure -bg #17191d

# Global State Variables
set display "0"
set clear_on_next 0
set angle_mode "Deg" ;# "Deg" or "Rad"
set inv_mode 0       ;# 0 = Normal, 1 = Inverse
set ans_value "0"
set last_op ""

# Custom Tcl Math Functions for Degree/Rad and Factorials
proc tcl::mathfunc::sin_deg {x} { return [expr {sin($x * 3.141592653589793 / 180.0)}] }
proc tcl::mathfunc::cos_deg {x} { return [expr {cos($x * 3.141592653589793 / 180.0)}] }
proc tcl::mathfunc::tan_deg {x} { return [expr {tan($x * 3.141592653589793 / 180.0)}] }
proc tcl::mathfunc::asin_deg {x} { return [expr {asin($x) * 180.0 / 3.141592653589793}] }
proc tcl::mathfunc::acos_deg {x} { return [expr {acos($x) * 180.0 / 3.141592653589793}] }
proc tcl::mathfunc::atan_deg {x} { return [expr {atan($x) * 180.0 / 3.141592653589793}] }
proc tcl::mathfunc::fact {n} {
    set result 1
    set max [expr {int($n)}]
    if {$max < 0} { return "Error" }
    for {set i 1} {$i <= $max} {incr i} { set result [expr {$result * $i}] }
    return $result
}

# Core Button Input Processing
proc press {key} {
    global display clear_on_next angle_mode inv_mode ans_value last_op

    if {$key == "AC"} {
        set display "0"
        set last_op ""
        .display icursor end
        .display xview end
        return
    }

    if {$key == "="} {
        # Auto-close any unclosed parentheses before running evaluations
        set open_count [regexp -all {\(} $display]
        set close_count [regexp -all {\)} $display]
        if {$open_count > $close_count} {
            append display [string repeat ")" [expr {$open_count - $close_count}]]
        }

        if {[regexp {([+\-×÷^][0-9.]+$)} $display match memory]} {
            set last_op $memory
        } elseif {$last_op != ""} {
            append display $last_op
        }

        set expr_str $display

        # Context-aware percentage scaling for sums and differences (e.g., 9-30% -> 9-(9*30*0.01))
        regsub -all {([0-9.]+)\s*([+\-])\s*([0-9.]+)\s*%} $expr_str {\1\2(\1*\3*0.01)} expr_str

        # Fallback standard percentage scaling for scaling items (e.g., 100×50% -> 100×(50*0.01))
        regsub -all {([0-9.]+)\s*%} $expr_str {(\1*0.01)} expr_str

        regsub -all {×} $expr_str {*} expr_str
        regsub -all {÷} $expr_str {/1.0/} expr_str
        regsub -all {π} $expr_str {3.141592653589793} expr_str
        regsub -all {e} $expr_str {2.718281828459045} expr_str
        regsub -all {Ans} $expr_str $ans_value expr_str
        regsub -all {EXP} $expr_str {*10**} expr_str
        regsub -all {\^} $expr_str {**} expr_str
        regsub -all {√\(([^)]+)\)} $expr_str {sqrt(\1)} expr_str
        regsub -all {([0-9.]+)!} $expr_str {fact(\1)} expr_str

        if {$angle_mode == "Deg"} {
            regsub -all {sin\(} $expr_str {sin_deg(} expr_str
            regsub -all {cos\(} $expr_str {cos_deg(} expr_str
            regsub -all {tan\(} $expr_str {tan_deg(} expr_str
            regsub -all {asin\(} $expr_str {asin_deg(} expr_str
            regsub -all {acos\(} $expr_str {acos_deg(} expr_str
            regsub -all {atan\(} $expr_str {atan_deg(} expr_str
        }

        regsub -all {ln\(} $expr_str {log(} expr_str
        regsub -all {log\(} $expr_str {log10(} expr_str

        if {[catch {expr double($expr_str)} result]} {
            set display "Error"
        } else {
            set display [string trimright [string trimright [format %.10f $result] "0"] "."]
            if {$display == ""} { set display "0" }
            set ans_value $display
        }
        set clear_on_next 1
        .display icursor end
        .display xview end
        return
    }

    if {$clear_on_next && [regexp {^[0-9.πe(]|sin|cos|tan|ln|log|√} $key]} {
        set display ""
    }
    set clear_on_next 0

    if {$display == "0" && [string first $key "+-*/×÷^%!)]"] == -1} {
        set display ""
    }

    if {[lsearch {sin cos tan ln log √ asin acos atan} $key] != -1} {
        append display "${key}("
    } else {
        append display $key
    }

    .display icursor end
    .display xview end
}

# Toggle Modes Logic
proc toggle_deg_rad {mode} {
    global angle_mode
    set angle_mode $mode
    if {$mode == "Deg"} {
        .fr_mode.b_deg configure -fg #a8c7fa -font {Helvetica 11 bold}
        .fr_mode.b_rad configure -fg #9aa0a6 -font {Helvetica 11}
    } else {
        .fr_mode.b_deg configure -fg #9aa0a6 -font {Helvetica 11}
        .fr_mode.b_rad configure -fg #a8c7fa -font {Helvetica 11 bold}
    }
}

proc toggle_inv {} {
    global inv_mode
    set inv_mode [expr {!$inv_mode}]
    if {$inv_mode} {
        .b_inv configure -bg #3c4043 -fg #a8c7fa
        .b_r2_c1 configure -text "asin" -command {press asin}
        .b_r3_c1 configure -text "acos" -command {press acos}
        .b_r4_c1 configure -text "atan" -command {press atan}
        .b_r2_c2 configure -text "10^x" -command {press "10^"}
        .b_r3_c2 configure -text "e^x"  -command {press "e^"}
        .b_r4_c2 configure -text "x²"   -command {press "^2"}
    } else {
        .b_inv configure -bg #202124 -fg #e3e3e3
        .b_r2_c1 configure -text "sin" -command {press sin}
        .b_r3_c1 configure -text "cos" -command {press cos}
        .b_r4_c1 configure -text "tan" -command {press tan}
        .b_r2_c2 configure -text "ln"  -command {press ln}
        .b_r3_c2 configure -text "log" -command {press log}
        .b_r4_c2 configure -text "√"   -command {press √}
    }
}

# --- Layout UI Grid Builder ---

# Formula Entry Display Area
entry .display -textvariable display -font {Helvetica 28} -justify right -bd 0 \
    -bg #17191d -fg #e3e3e3 -insertbackground #e3e3e3 -selectbackground #3c4043
grid .display -row 0 -column 0 -columnspan 7 -sticky nsew -padx 20 -pady 25

# Dynamically configure weights for proportional sizing
grid rowconfigure . 0 -weight 1
for {set r 1} {$r <= 5} {incr r} { grid rowconfigure . $r -weight 1 }
for {set c 0} {$c <= 6} {incr c} { grid columnconfigure . $c -weight 1 }

# Row 1: Deg/Rad Frame Toggles
frame .fr_mode -bg #202124
grid .fr_mode -row 1 -column 0 -columnspan 2 -sticky nsew -padx 3 -pady 3

label .fr_mode.b_deg -text "Deg" -bg #202124 -fg #a8c7fa -font {Helvetica 11 bold} -cursor hand2
label .fr_mode.b_div -text "|" -bg #202124 -fg #3c4043 -font {Helvetica 11}
label .fr_mode.b_rad -text "Rad" -bg #202124 -fg #9aa0a6 -font {Helvetica 11} -cursor hand2
pack .fr_mode.b_deg .fr_mode.b_div .fr_mode.b_rad -side left -expand 1

bind .fr_mode.b_deg <Button-1> {toggle_deg_rad "Deg"}
bind .fr_mode.b_rad <Button-1> {toggle_deg_rad "Rad"}

# Button Matrix Definitions
set layout {
    {"x!" 1 2 "op"} {"(" 1 3 "op"}  {")" 1 4 "op"}  {"%" 1 5 "op"}  {"AC" 1 6 "ac"}
    {"Inv" 2 0 "inv"} {"sin" 2 1 "op"} {"ln" 2 2 "op"}  {"7" 2 3 "num"} {"8" 2 4 "num"} {"9" 2 5 "num"} {"÷" 2 6 "op"}
    {"π" 3 0 "op"}   {"cos" 3 1 "op"} {"log" 3 2 "op"} {"4" 3 3 "num"} {"5" 3 4 "num"} {"6" 3 5 "num"} {"×" 3 6 "op"}
    {"e" 4 0 "op"}   {"tan" 4 1 "op"} {"√" 4 2 "op"}   {"1" 4 3 "num"} {"2" 4 4 "num"} {"3" 4 5 "num"} {"−" 4 6 "op"}
    {"Ans" 5 0 "op"} {"EXP" 5 1 "op"} {"x^y" 5 2 "op"} {"0" 5 3 "num"} {"." 5 4 "num"} {"=" 5 5 "eq"}  {"+" 5 6 "op"}
}

# Construct Grid Buttons
foreach btn $layout {
    lassign $btn lbl r c type
    set name ".b_r${r}_c${c}"
    if {$type == "inv"} { set name ".b_inv" }

    set bg "#202124" ; set fg "#e3e3e3"
    if {$type == "num"} { set bg "#303134"; set fg "#f1f3f4" }
    if {$type == "eq"}  { set bg "#a8c7fa"; set fg "#202124" }
    if {$type == "ac"}  { set fg "#e8eaed" }

    set cmd_lbl $lbl
    if {$lbl == "x^y"} { set cmd_lbl "^" }
    if {$lbl == "−"}   { set cmd_lbl "-" }
    if {$lbl == "x!"}  { set cmd_lbl "!" }

    if {$type == "inv"} {
        button $name -text $lbl -font {Helvetica 12} -bg $bg -fg $fg -bd 0 \
            -relief flat -activebackground #3c4043 -activeforeground $fg -command {toggle_inv}
    } else {
        button $name -text $lbl -font {Helvetica 12} -bg $bg -fg $fg -bd 0 \
            -relief flat -activebackground #3c4043 -activeforeground $fg -command [list press $cmd_lbl]
    }
    grid $name -row $r -column $c -sticky nsew -padx 4 -pady 4
}

# --- Global & Focused Keyboard Bindings Engine ---

# Intercept and process raw keystrokes contextually
proc handle_key {char target_widget} {
    global display clear_on_next

    # If standard text operations change math glyphs
    if {$char == "*"} { set char "×" }
    if {$char == "/"} { set char "÷" }

    # Filter only permitted characters
    if {[regexp {^[0-9.×÷+\-()%\^!]$} $char]} {
        press $char
    }
}

# Custom handler for Backspace key behavior respecting cursor position
proc handle_backspace {} {
    global display clear_on_next
    if {$clear_on_next || $display == "Error"} {
        set display "0"
        set clear_on_next 0
    } else {
        set idx [.display index insert]
        if {$idx > 0} {
            set start [expr {$idx - 1}]
            .display delete $start $idx
            if {$display == ""} {
                set display "0"
            }
        }
    }
    .display xview end
}

# Global Action Bindings
bind . <Return> {press "="}
bind . <KP_Enter> {press "="}
bind . <Escape> {press "AC"}
bind . <BackSpace> {handle_backspace}
bind . <Delete> {press "AC"}
bind . <KP_Delete> {press "AC"}
bind . <Key> {handle_key %A .}

# Focused Input Field Behavior overrides (Prevents double inputting)
bind .display <Return> {press "="; break}
bind .display <KP_Enter> {press "="; break}
bind .display <Escape> {press "AC"; break}
bind .display <BackSpace> {handle_backspace; break}
bind .display <Delete> {press "AC"; break}
bind .display <KP_Delete> {press "AC"; break}
bind .display <Key> {handle_key %A .display; break}
