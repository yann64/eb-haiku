' Step 3: a form-style grid - labels in column 0, fields in column 1, a
' button spanning both columns on its own row. Verified visually via an
' external screenshot (see scripts/haiku_verify.sh).

#include once "../src/lib.bas"

CONST H_QUIT_ON_WINDOW_CLOSE = 1048576

DIM app AS HApplication
app = HApplicationCreate("application/x-vnd.EbHaiku-GridLayoutTest")

DIM w AS HWindow
w = HWindowCreate(100, 100, 420, 260, "eb-haiku grid layout test", H_QUIT_ON_WINDOW_CLOSE)

DIM grid AS HGridLayout
grid = HGridLayoutCreate(8, 6)
CALL HTwoDimensionalLayoutSetInsets(grid.handle, 10, 10, 10, 10)
CALL HWindowSetLayout(w, grid.handle)

DIM nameLbl AS HStringView
nameLbl = HStringViewCreate(0, 0, 0, 0, "nameLbl", "Name:")
CALL HGridLayoutAddViewAt(grid, nameLbl.handle, 0, 0, 1, 1)

DIM nameField AS HTextControl
nameField = HTextControlCreate(0, 0, 0, 0, "nameField", "", "eBasic", 1)
CALL HGridLayoutAddViewAt(grid, nameField.handle, 1, 0, 1, 1)

DIM emailLbl AS HStringView
emailLbl = HStringViewCreate(0, 0, 0, 0, "emailLbl", "Email:")
CALL HGridLayoutAddViewAt(grid, emailLbl.handle, 0, 1, 1, 1)

DIM emailField AS HTextControl
emailField = HTextControlCreate(0, 0, 0, 0, "emailField", "", "eb@example.com", 2)
CALL HGridLayoutAddViewAt(grid, emailField.handle, 1, 1, 1, 1)

DIM submitBtn AS HButton
submitBtn = HButtonCreate(0, 0, 0, 0, "submit", "Submit", 3333)
CALL HGridLayoutAddViewAt(grid, submitBtn.handle, 0, 2, 2, 1)

CALL HGridLayoutSetColumnWeight(grid, 1, 1)

CALL HWindowShow(w)
PRINT "shown ok"

CALL Sleep(2000)

CALL HWindowClose(w)
CALL HApplicationRun(app)
CALL HApplicationFree(app)

PRINT "grid layout test ok"
