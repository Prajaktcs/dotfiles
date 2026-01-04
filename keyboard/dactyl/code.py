import board
from kmk.kmk_keyboard import KMKKeyboard
from kmk.keys import KC
from kmk.scanners import DiodeOrientation
from kmk.modules.split import Split, SplitType

keyboard = KMKKeyboard()

# --- 1. PIN CONFIGURATION ---
# We add GP12 to the rows to accommodate the Right side's extra key
keyboard.row_pins = (
    board.GP0,
    board.GP1,
    board.GP2,
    board.GP3,
    board.GP4,
    board.GP5,
    board.GP12,
)
keyboard.col_pins = (board.GP6, board.GP7, board.GP8, board.GP9, board.GP10, board.GP11)
keyboard.diode_orientation = DiodeOrientation.ROW2COL

# --- 2. SPLIT CONFIGURATION (Using GP14/15) ---
split = Split(
    data_pin=board.GP14, data_pin2=board.GP15, use_pio=True, split_type=SplitType.UART
)
keyboard.modules.append(split)

# --- 3. COORD MAPPING (The Translator) ---
# This defines exactly where the physical switches are.
# 0-35 are Left side intersections, 36-77 are Right side.
# We use x to represent a physical key and ____ to represent an empty space.
# fmt: off
keyboard.coord_mapping = [
    0,  1,  2,  3,  4,  5,    36, 37, 38, 39, 40, 41,
    6,  7,  8,  9,  10, 11,   42, 43, 44, 45, 46, 47,
    12, 13, 14, 15, 16, 17,   48, 49, 50, 51, 52, 53,
    18, 19, 20, 21, 22, 23,   54, 55, 56, 57, 58, 59,
    26, 27, 28, 29,           62, 63, 64, 65,
    30, 31, 32,               66, 67, 72  # 72 is your extra Row 6 key
]

# --- 4. THE KEYMAP ---
# Optimized for programming (SQL, Ruby, Python, Java, YAML, Terraform, K8s)
keyboard.keymap = [
    # ===== LAYER 0: Base Layer =====
    [
        # Row 0 - Numbers (easy access for programming)
        KC.N1,  KC.N2,  KC.N3,  KC.N4,  KC.N5,  KC.N6,     KC.N7,  KC.N8,  KC.N9,  KC.N0,  KC.MINS,KC.EQL,
        # Row 1 - Standard QWERTY
        KC.TAB, KC.Q,   KC.W,   KC.E,   KC.R,   KC.T,      KC.Y,   KC.U,   KC.I,   KC.O,   KC.P,   KC.BSPC,
        # Row 2 - Home row (Ctrl instead of Caps for better programming)
        KC.LCTL,KC.A,   KC.S,   KC.D,   KC.F,   KC.G,      KC.H,   KC.J,   KC.K,   KC.L,   KC.SCLN,KC.QUOT,
        # Row 3 - Bottom row
        KC.LSFT,KC.Z,   KC.X,   KC.C,   KC.V,   KC.B,      KC.N,   KC.M,   KC.COMM,KC.DOT, KC.SLSH,KC.RSFT,
        # Row 4 - Modifiers and brackets
        KC.GRV, KC.LBRC,KC.RBRC,KC.BSLS,                   KC.LEFT,KC.DOWN,KC.UP,  KC.RGHT,
        # Row 5 - Thumb cluster (Esc + Space + Layers)
        KC.ESC, KC.SPC, KC.MO(1),                          KC.MO(2),KC.SPC, KC.ENT
    ],

    # ===== LAYER 1: Symbols & Navigation =====
    [
        # Row 0 - Symbols (! @ # $ % ^ & * ( ))
        KC.EXLM,KC.AT,  KC.HASH,KC.DLR, KC.PERC,KC.CIRC,   KC.AMPR,KC.ASTR,KC.LPRN,KC.RPRN,KC.UNDS,KC.PLUS,
        # Row 1 - Brackets and navigation
        KC.TRNS,KC.TRNS,KC.TRNS,KC.TRNS,KC.TRNS,KC.TRNS,   KC.HOME,KC.PGDN,KC.PGUP,KC.END, KC.LBRC,KC.DEL,
        # Row 2 - Braces and symbols (for code blocks)
        KC.TRNS,KC.TRNS,KC.TRNS,KC.TRNS,KC.TRNS,KC.TRNS,   KC.LEFT,KC.DOWN,KC.UP,  KC.RGHT,KC.LCBR,KC.RCBR,
        # Row 3 - More symbols
        KC.TRNS,KC.TRNS,KC.TRNS,KC.TRNS,KC.TRNS,KC.TRNS,   KC.TRNS,KC.TRNS,KC.LT,  KC.GT,  KC.PIPE,KC.TRNS,
        # Row 4 - Tilde and brackets
        KC.TILD,KC.TRNS,KC.TRNS,KC.TRNS,                   KC.TRNS,KC.TRNS,KC.TRNS,KC.TRNS,
        # Row 5 - Thumbs
        KC.TRNS,KC.TRNS,KC.TRNS,                           KC.TRNS,KC.TRNS,KC.TRNS
    ],

    # ===== LAYER 2: Function Keys, Media Controls & Numpad =====
    [
        # Row 0 - Function keys
        KC.F1,  KC.F2,  KC.F3,  KC.F4,  KC.F5,  KC.F6,     KC.F7,  KC.F8,  KC.F9,  KC.F10, KC.F11, KC.F12,
        # Row 1 - Media controls (left) & Numpad (right)
        KC.MUTE,KC.VOLD,KC.VOLU,KC.MPLY,KC.MSTP,KC.MNXT,   KC.N7,  KC.N8,  KC.N9,  KC.PAST,KC.TRNS,KC.TRNS,
        # Row 2 - More media (left) & Numpad (right)
        KC.TRNS,KC.MPRV,KC.TRNS,KC.TRNS,KC.TRNS,KC.TRNS,   KC.N4,  KC.N5,  KC.N6,  KC.PMNS,KC.TRNS,KC.TRNS,
        # Row 3 - Numpad continued
        KC.TRNS,KC.TRNS,KC.TRNS,KC.TRNS,KC.TRNS,KC.TRNS,   KC.N1,  KC.N2,  KC.N3,  KC.PPLS,KC.TRNS,KC.TRNS,
        # Row 4
        KC.TRNS,KC.TRNS,KC.TRNS,KC.TRNS,                   KC.N0,  KC.N0,  KC.PDOT,KC.PENT,
        # Row 5 - Thumbs
        KC.TRNS,KC.TRNS,KC.TRNS,                           KC.TRNS,KC.TRNS,KC.TRNS
    ]
]
# fmt: on

if __name__ == "__main__":
    keyboard.go()
