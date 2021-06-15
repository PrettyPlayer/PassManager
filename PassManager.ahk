SendMode Input
SetWorkingDir %A_ScriptDir%
#NoEnv
#Persistent
#SingleInstance, Force
#Include Class_SQLiteDB.ahk

Gosub Initialize
return

;=============================	INITIALIZE ======================================

Initialize:
	NameIni := "PassManager"
	
	DBFileName := A_ScriptDir . "\" . NameIni . ".DB"
	DB := new SQLiteDB
	_String := "WinText#"

	menuOpenned := 1
	authorized := 0
	
	lang1 := "Eng"
	lang2 := "Рус"
	langCount := 2
	
	Gosub StartProgram
return

;=============================	START PROGRAM ======================================

StartProgram:
	IniRead, authorizeMenuW , %NameIni%.ini, Menu, authorizeMenuW 
	IniRead, authorizeMenuH , %NameIni%.ini, Menu, authorizeMenuH 
	IniRead, mainMenuW , %NameIni%.ini, Menu, mainMenuW 
	IniRead, mainMenuH , %NameIni%.ini, Menu, mainMenuH
	IniRead, newAccMenuW , %NameIni%.ini, Menu, newAccMenuW 
	IniRead, newAccMenuH , %NameIni%.ini, Menu, newAccMenuH 
	IniRead, lang , %NameIni%.ini, Menu, lang
	IniRead, exitHotKey , %NameIni%.ini, HotKeys, exitHotKey
	
	;Hotkey, VK63, OpenMenu
	Hotkey, %exitHotKey%, exitFromApp
	
	Gosub OpenBD
	Gosub LoadGui1
	Gosub LoadGui2
	Gosub LoadGui3
	Gosub LoadGui4
	Gosub LoadGui5
	Gosub LoadGuiList
	Gosub MenuAuthorize
return

;=============================	HOTKEYS ======================================

DestroyAndClose:
	If !DB.CloseDB()
		MsgBox, 16, SQLite Error, % "Msg:`t" . DB.ErrorMsg . "`nCode:`t" . DB.ErrorCode
	Gui, Destroy
	ExitApp
return

exitFromApp: ; 1B (ESC)
	IfWinActive, %NameIni%.ahk
	{
		gosub DestroyAndClose
		return
	}
	IfWinActive, %NameIni%.exe
	{
		gosub DestroyAndClose
		return
	}
	SendEvent {ESCAPE}
return

;Numpad9::
;	Gosub DeleteGui
;return

;Numpad1::
;	ControlGetFocus, OutputVar, %NameIni%.ahk
;	sleep 500
;	if ErrorLevel
;		MsgBox, The target window doesn't exist or none of its controls has input focus.
;	else
;		MsgBox, Control with focus = %OutputVar%
;return

;Numpad2::
;	ExitApp
;return

OpenMenu: ; Numpad3
	if(menuOpenned){
		Gosub MenuHide
		menuOpenned:=0
	}
	else{
		menuOpenned := 1
		if(authorized == 0){
			Gosub MenuAuthorize
		}
		else{
			Gosub MenuMain
		}
	}
return

;=============================	FUNCTIONS ======================================

OpenBD:
	IfExist, %A_ScriptDir%\%NameIni%.DB
		NeedCreate := 0
	IfNotExist, %A_ScriptDir%\%NameIni%.DB
		NeedCreate := 1

	If !DB.OpenDB(DBFileName) {
	   MsgBox, 16, SQLite Error, % "Msg:`t" . DB.ErrorMsg . "`nCode:`t" . DB.ErrorCode, 1
	   ExitApp
	}

	If (NeedCreate){
		SQL := "CREATE TABLE Users (Id INTEGER UNIQUE NOT NULL PRIMARY KEY ASC AUTOINCREMENT, Password TINYTEXT UNIQUE NOT NULL);"
		If !DB.Exec(SQL)
		   MsgBox, 16, SQLite Error, % "Msg:`t" . DB.ErrorMsg . "`nCode:`t" . DB.ErrorCode, 1

		SQL := "CREATE TABLE Information (AccId INTEGER UNIQUE NOT NULL PRIMARY KEY ASC AUTOINCREMENT, UserId INTEGER, TypeId INTEGER, NameApp TINYTEXT, UserName TINYTEXT, Login TINYTEXT, Password TINYTEXT, Mail TINYTEXT, Notes TEXT, FOREIGN KEY(UserId) REFERENCES Users(Id), FOREIGN KEY(TypeId) REFERENCES Types(Id));"
		If !DB.Exec(SQL)
		   MsgBox, 16, SQLite Error, % "Msg:`t" . DB.ErrorMsg . "`nCode:`t" . DB.ErrorCode, 1

		SQL := "CREATE TABLE Types (Id INTEGER UNIQUE NOT NULL PRIMARY KEY ASC AUTOINCREMENT, NameType TINYTEXT);"
		If !DB.Exec(SQL)
		   MsgBox, 16, SQLite Error, % "Msg:`t" . DB.ErrorMsg . "`nCode:`t" . DB.ErrorCode, 1
		
		DB.Exec("BEGIN TRANSACTION;")
		SQLStr := ""
		SQL := "INSERT INTO Types('NameType') VALUES('Sites');"
		If !DB.Exec(SQL)
		   MsgBox, 16, SQLite Error, % "Msg:`t" . DB.ErrorMsg . "`nCode:`t" . DB.ErrorCode, 1
		   SQL := "INSERT INTO Types('NameType') VALUES('Applications');"
		If !DB.Exec(SQL)
		   MsgBox, 16, SQLite Error, % "Msg:`t" . DB.ErrorMsg . "`nCode:`t" . DB.ErrorCode, 1
		   SQL := "INSERT INTO Types('NameType') VALUES('Other');"
		If !DB.Exec(SQL)
		   MsgBox, 16, SQLite Error, % "Msg:`t" . DB.ErrorMsg . "`nCode:`t" . DB.ErrorCode, 1
		DB.Exec("COMMIT TRANSACTION;")
		SQLStr := ""
	}
return

CenterText(NumGui, NameControl, Width) ; (Number, "Text", Var) 
{
	GuiControl, %NumGui%: Move, %NameControl%, w%Width% +0x1 
	GuiControl, %NumGui%: +Center, %NameControl%
}

	; ==================== Refresh information for quick fill ComboBoxes, ListBox ==========================
RefreshBoxes:
	GuiControl 3: , ListBoxFirst, |
	GuiControl 3: , ListBoxSecond, |
	GuiControl 3: , ListBoxThird, |
	GuiControl 3: , ListBoxAll, |
	GuiControl 4: , AccNameApp, |
	GuiControl 4: , AccUserName, |
	GuiControl 4: , AccLogin, |
	GuiControl 4: , AccPassword,
	GuiControl 4: , AccMail, |
	GuiControl 4: , AccNotes,
	FullAccNameApp := NULL
	FullAccUserName := NULL
	FullAccLogin := NULL
	FullAccMail := NULL
	SQL := "SELECT * FROM Information;"
	DB.GetTable(SQL, Result)
	SQLStr := ""
	_SQL := ""
	row1 := ""
	row2 := ""
	lpcounter := Result.RowCount
	Count := 0
	ASAccAccId := []
	ASAccNameApp := []
	ASAccUserName := []
	ASAccLogin := []
	ASAccPassword := []
	ASAccMail := []
	ASAccNotes := []
	Loop %lpcounter% {
		AccIdInformation := Result.Rows[A_Index, 1]
		UserIdInformation := Result.Rows[A_Index, 2]
		TypeIdInformation := Result.Rows[A_Index, 3]
		NameAppInformation := Result.Rows[A_Index, 4] ;
		UserNameInformation := Result.Rows[A_Index, 5] ;
		LoginInformation := Result.Rows[A_Index, 6] ;
		PasswordInformation := Result.Rows[A_Index, 7] ;
		MailInformation := Result.Rows[A_Index, 8] ;
		NotesInformation := Result.Rows[A_Index, 9] ;
		;MsgBox % Result.Rows[A_Index, 2]
		if(UserIdInformation == CurrentIdUser){
			if(ListBox%MenuTabName% == NameAppInformation){
				Count += 1
				ASAccAccId[Count] := AccIdInformation
				ASAccNameApp[Count] := NameAppInformation
				ASAccUserName[Count] := UserNameInformation
				ASAccLogin[Count] := LoginInformation
				ASAccPassword[Count] := PasswordInformation
				ASAccMail[Count] := MailInformation
				ASAccNotes[Count] := NotesInformation
				GuiControl 3: , SAccNameApp, % ASAccNameApp[1]
				GuiControl 3: , SAccUserName, % ASAccUserName[1]
				GuiControl 3: , SAccLogin, % ASAccLogin[1]
				GuiControl 3: , SAccPassword, % ASAccPassword[1]
				GuiControl 3: , SAccMail, % ASAccMail[1]
				GuiControl 3: , SAccNotes, % ASAccNotes[1]
				GuiControl 3: +Range1-%Count%, SUpDown 
				GuiControl 3: , SUpDown , Count
			}
			if NameAppInformation not in %FullAccNameApp%
			{
				if (NameAppInformation != NULL){
					IfInString, NameAppInformation, %search%
					{
						if (TypeIdInformation == 1)
							GuiControl 3: , ListBoxFirst, %NameAppInformation%
						if (TypeIdInformation == 2)
							GuiControl 3: , ListBoxSecond, %NameAppInformation%
						if (TypeIdInformation == 3)
							GuiControl 3: , ListBoxThird, %NameAppInformation%
						GuiControl 3: , ListBoxAll, %NameAppInformation%
						;MsgBox %NameAppInformation%, %FullAccNameApp%, %A_Index%, %lpcounter%
						GuiControl 4: , AccNameApp, %NameAppInformation%
						FullAccNameApp .= NameAppInformation . ","
					}
				}
			}
			if UserNameInformation not in %FullAccUserName%
			{
				if (NameAppInformation != NULL){
					GuiControl 4: , AccUserName, %UserNameInformation%
					FullAccUserName .= UserNameInformation . ","
				}
			}
			if LoginInformation not in %FullAccLogin%
			{
				if (NameAppInformation != NULL){
					GuiControl 4: , AccLogin, %LoginInformation%
					FullAccLogin .= LoginInformation . ","
				}
			}
			if MailInformation not in %FullAccMail%
			{
				if (NameAppInformation != NULL){
					GuiControl 4: , AccMail, %MailInformation%
					FullAccMail .= MailInformation . ","
				}
			}
		}
	}
return

;=============================	FUNCTIONS LOAD MENU ======================================

DeleteGui:
	Gui, 1: Destroy
	Gui, 2: Destroy
	Gui, 3: Destroy
	Gui, 4: Destroy
	Gui, 5: Destroy
	Gosub StartProgram
return

LoadGui1:
	loop, %langCount%
	{
		if(lang == Lang%A_Index%)
			langPos := A_Index
	}
	
	Gui, 1: Font, S12, Verdana
	Gui, 1: -Caption
	Gui, 1: Add, Text, -wrap vWinText , Enter password
	Gui, 1: Add, Edit, Password -wrap xp+15 yp+30 w150 r1 vAPass
	Gui, 1: Add, Button, -wrap w150 vAuthorize gButtonAuthorize, Authorize
	Gui, 1: Add, DropDownList, -wrap y+11 x10 w60 choose%langPos% vLang gChangeLang, %Lang1%|%Lang2%
	Gui, 1: Add, Button, -wrap x+11 yp-1 h28 w120 vNewUser gButtonNewuser, New User
	if(lang == lang2){
		GuiControl 1: , WinText, Введите пароль
		GuiControl 1: , Authorize, Войти
		GuiControl 1: , NewUser, Регистрация
	}
return

LoadGui2:
	Gui, 2: Font, S12, Verdana
	Gui, 2: -Caption
	Gui, 2: Add, Text, -wrap vWinText , Enter password
	Gui, 2: Add, Edit, Password -wrap xp+15 yp+30 w150 r1 vNPass
	Gui, 2: Add, Button, -wrap w150 vCreateNewUser g2ButtonCreateNewUser, Create New User
	Gui, 2: Add, Button, -wrap x55 y+10 h28 w100 vBack g2ButtonBack, Back
	if(lang == lang2){
		GuiControl 2: , WinText, Введите пароль
		GuiControl 2: , CreateNewUser, Создать
		GuiControl 2: , Back, Назад
	}
return

LoadGui3:
	Gui, 3: Font, S12, Verdana
	Gui, 3: -Caption
	;Gui, 3: Add, Edit, -wrap xp+295 yp+12 w174 h23 vSearch
	Gui, 3: Add, Edit, w470 h23 gChangedSearch vSearch
	Gui, 3: Add, Tab, section vMenuTabName AltSubmit w470 h394, All
	Gui, 3: Tab, 1
	Gui, 3: Add, ListBox, r16 w210 gClickMenuTabName vListBoxAll
	Gui, 3: Tab, 2
	Gui, 3: Add, ListBox, r16 w210 gClickMenuTabName vListBoxFirst
	Gui, 3: Tab, 3
	Gui, 3: Add, ListBox, r16 w210 gClickMenuTabName vListBoxSecond
	Gui, 3: Tab, 4
	Gui, 3: Add, ListBox, r16 w210 gClickMenuTabName vListBoxThird
	Gui, 3: Tab
	Gui, 3: Add, Button, -wrap xp-1 yp+310 w50 vNewAccount g3ButtonNewAccount, New Account
	Gui, 3: Add, Button, hidden -wrap xp+134 w78 vDelete g3ButtonDelete, Delete
	Gui, 3: Font, S9, Verdana
	Gui, 3: Add, Text, hidden -wrap x258 y75 w200 vSWinText1, Site/NameApp/Name
	Gui, 3: Add, Edit, hidden ReadOnly -wrap y+2 w200 vSAccNameApp
	Gui, 3: Add, Text, hidden -wrap y+3 w200 vSWinText2, UserName
	Gui, 3: Add, Edit, hidden ReadOnly -wrap y+2 w200 vSAccUserName
	Gui, 3: Add, Text, hidden -wrap y+3 w200 vSWinText3, Login
	Gui, 3: Add, Edit, hidden ReadOnly -wrap y+2 w200 vSAccLogin
	Gui, 3: Add, Text, hidden -wrap y+3 w200 vSWinText4, Password
	Gui, 3: Add, Edit, hidden ReadOnly -wrap y+2 w200 vSAccPassword
	Gui, 3: Add, Text, hidden -wrap y+3 w200 vSWinText5, Mail
	Gui, 3: Add, Edit, hidden ReadOnly -wrap y+2 w200 vSAccMail
	Gui, 3: Add, Text, hidden -wrap y+3 w200 vSWinText6, Notes
	Gui, 3: Add, Edit, hidden ReadOnly y+2 r4 w200 vSAccNotes
	Gui, 3: Add, Edit, hidden xp+150 y+11 w50 vSUpDownEdit
	Gui, 3: Add, UpDown, hidden Range1-1 gClickUpDown vSUpDown, 1
	if(lang == lang2){
		GuiControl 3: , MenuTabName, |Все
		GuiControl 3: , NewAccount, Добавить
		GuiControl 3: , Delete, Удалить
		GuiControl 3: , SWinText1, Сайт/Приложение/Имя
		GuiControl 3: , SWinText2, Имя пользователя
		GuiControl 3: , SWinText3, Логин
		GuiControl 3: , SWinText4, Пароль
		GuiControl 3: , SWinText5, Почта
		GuiControl 3: , SWinText6, Заметка
	}
return

LoadGui4:
	Gui, 4: Font, S12, Verdana
	Gui, 4: -Caption
	Gui, 4: Font, S18, Verdana
	Gui, 4: Add, Text, h58 vWinText1, Record a new`naccount
	Gui, 4: Font, S12, Verdana
	Gui, 4: Add, Text, -wrap vWinText2, AccountType
	Gui, 4: Add, DropDownList, -wrap xp+28 y+2 w200 choose1 vAccTypeId, %ComboBoxTypes%
	Gui, 4: Add, Text, -wrap y+11 vWinText3, Site/NameApp/Name
	Gui, 4: Add, ComboBox, -wrap y+2 w200 vAccNameApp
	Gui, 4: Add, Text, -wrap y+11 vWinText4, UserName
	Gui, 4: Add, ComboBox, -wrap y+2 w200 vAccUserName
	Gui, 4: Add, Text, -wrap y+11 vWinText5, Login
	Gui, 4: Add, ComboBox, -wrap y+2 w200 vAccLogin
	Gui, 4: Add, Text, -wrap y+11 vWinText6, Password
	Gui, 4: Add, Edit, -wrap y+2 w200 vAccPassword
	Gui, 4: Add, Text, -wrap y+11 vWinText7, Mail
	Gui, 4: Add, ComboBox, -wrap y+2 w200 vAccMail
	Gui, 4: Add, Text, -wrap y+11 vWinText8, Notes
	Gui, 4: Add, Edit, y+2 r4 w200 vAccNotes
	Gui, 4: Add, Button, -wrap xp-40 yp+90 w100 vAddNewAccount g4ButtonAddNewAccount, Add New Account
	Gui, 4: Add, Button, -wrap xp+167 yp+0 w113 vBack g4ButtonBack, Back
	if(lang == lang2){
		Gui, 4: Font, S18, Verdana
		GuiControl 4: Font, WinText1
		GuiControl 4: , WinText1, Добавление нового`nаккаунта
		GuiControl 4: , WinText2, Тип аккаунта
		GuiControl 4: , WinText3, Сайт/Приложение/Имя
		GuiControl 4: , WinText4, Имя пользователя
		GuiControl 4: , WinText5, Логин
		GuiControl 4: , WinText6, Пароль
		GuiControl 4: , WinText7, Почта
		GuiControl 4: , WinText8, Заметка
		GuiControl 4: , AddNewAccount, Добавить
		GuiControl 4: , Back, Назад
	}
return

LoadGui5:
	Gui, 5: Font, S12, Verdana
	Gui, 5: -Caption
	Gui, 5: Font, S18, Verdana
	Gui, 5: Add, Text, -wrap vCWinText1, Change existing account
	Gui, 5: Font, S12, Verdana
	Gui, 5: Add, Text, -wrap vCWinText2, AccountType
	Gui, 5: Add, DropDownList, -wrap xp+28 y+2 w200 choose1 vCAccTypeId, %ComboBoxTypes%
	Gui, 5: Add, Text, -wrap y+11 vCWinText3, Site/NameApp/Name
	Gui, 5: Add, ComboBox, -wrap y+2 w200 vCAccNameApp
	Gui, 5: Add, Text, -wrap y+11 vCWinText4, UserName
	Gui, 5: Add, ComboBox, -wrap y+2 w200 vCAccUserName
	Gui, 5: Add, Text, -wrap y+11 vCWinText5, Login
	Gui, 5: Add, ComboBox, -wrap y+2 w200 vCAccLogin
	Gui, 5: Add, Text, -wrap y+11 vCWinText6, Password
	Gui, 5: Add, Edit, -wrap y+2 w200 vCAccPassword
	Gui, 5: Add, Text, -wrap y+11 vCWinText7, Mail
	Gui, 5: Add, ComboBox, -wrap y+2 w200 vCAccMail
	Gui, 5: Add, Text, -wrap y+11 vCWinText8, Notes
	Gui, 5: Add, Edit, y+2 r4 w200 vCAccNotes
	Gui, 5: Add, Button, -wrap xp-40 yp+90 w100, Change Account
	Gui, 5: Add, Button, -wrap xp+167 yp+0 w113, Back
return

LoadGuiList:
	; ==================== Get types from bd for quick fill DropDownList ==========================
	SQL := "SELECT * FROM Types;"
	DB.GetTable(SQL, Result)
	SQLStr := ""
	_SQL := ""
	row1 := ""
	row2 := ""
	lpcounter := Result.RowCount
	ComboBoxTypes := NULL
	GuiControl 4: , AccTypeId, |
	Loop %lpcounter% {
		IdTypes := Result.Rows[A_Index, 1]
		NameTypeTypes := Result.Rows[A_Index, 2]
		if(lang == lang2){
			if(NameTypeTypes == "Sites")
				NameTypeTypes := "Сайты"
			if(NameTypeTypes == "Applications")
				NameTypeTypes := "Приложения"
			if(NameTypeTypes == "Other")
				NameTypeTypes := "Другое"
		}
		GuiControl 3: , MenuTabName, %NameTypeTypes%
		if (ComboBoxTypes == NULL){
			ComboBoxTypes := NameTypeTypes
			StringReplace, ComboBoxTypes, ComboBoxTypes, %ComboBoxTypes%, %ComboBoxTypes%|
		}
		else{
			StringReplace, ComboBoxTypes, ComboBoxTypes, %ComboBoxTypes%, %ComboBoxTypes%|%NameTypeTypes%
		}
	}
	GuiControl 4: , AccTypeId, %ComboBoxTypes%
	Gosub RefreshBoxes
return

;=============================	FUNCTIONS SHOW MENU ======================================

ControlShowGUI(Option)
{
	GuiControl 3: %Option%, SWinText1
	GuiControl 3: %Option%, SWinText2
	GuiControl 3: %Option%, SWinText3
	GuiControl 3: %Option%, SWinText4
	GuiControl 3: %Option%, SWinText5
	GuiControl 3: %Option%, SWinText6
	GuiControl 3: %Option%, SAccNameApp
	GuiControl 3: %Option%, SAccUserName
	GuiControl 3: %Option%, SAccLogin
	GuiControl 3: %Option%, SAccPassword
	GuiControl 3: %Option%, SAccMail
	GuiControl 3: %Option%, SAccNotes
	GuiControl 3: %Option%, SUpDown
	GuiControl 3: %Option%, SUpDownEdit
	GuiControl 3: %Option%, Delete
}

MenuHide:
	Gui, 1: Hide
	Gui, 2: Hide
	Gui, 3: Hide
	Gui, 4: Hide
return

MenuAuthorize:
	Gosub MenuHide
	Gui, 1: Show, Restore w%authorizeMenuW% h%authorizeMenuH%
	CenterText(1, "WinText", authorizeMenuW)
return

MenuNewUser:
	Gosub MenuHide
	Gui, 2: Show, Restore w%authorizeMenuW% h%authorizeMenuH%
	CenterText(2, "WinText", authorizeMenuW)
return

MenuMain:
	Gosub MenuHide
	Gui, 3: Show, Restore w%mainMenuW% h%mainMenuH%
	Gui, 3: Submit, nohide
return

MenuNewAccount:
	Gosub MenuHide
	Gui, 4: Show, Restore w%newAccMenuW% h%newAccMenuH%
	; ==================== Center text ==========================
	Loop, 8 {
		StringReplace, String, _String, #, %A_Index%, All
		CenterText(4, String, newAccMenuW)
	}
return


;=============================	FUNCTIONS BUTTONS ======================================

ChangeLang:
	Gui, 1: Submit, Nohide
	GuiControlGet, Lang
	IniWrite, %Lang%, %NameIni%.ini, Menu, lang
	Gosub DeleteGui
return

ChangedSearch:
	Gui, 3: Submit, Nohide
	GuiControlGet, Search
	Gosub RefreshBoxes
return

ClickUpDown:
	Gui, 3: Submit, Nohide
	GuiControlGet, SUpDown
	GuiControl 3: , SAccNameApp, % ASAccNameApp[SUpDown]
	GuiControl 3: , SAccUserName, % ASAccUserName[SUpDown]
	GuiControl 3: , SAccLogin, % ASAccLogin[SUpDown]
	GuiControl 3: , SAccPassword, % ASAccPassword[SUpDown]
	GuiControl 3: , SAccMail, % ASAccMail[SUpDown]
	GuiControl 3: , SAccNotes, % ASAccNotes[SUpDown]
return

ClickMenuTabName:
	Gui, 3: Submit, Nohide
	GuiControlGet, MenuTabName
	GuiControlGet, ListBox%MenuTabName%
	if(A_GuiControlEvent == "Normal"){
		if(ListBox%MenuTabName% == NULL){
			ControlShowGUI("Hide")
		}
		if(ListBox%MenuTabName% != NULL){
			ControlShowGUI("Show")
			Gosub RefreshBoxes
		}
	}
	if(A_GuiControlEvent == "DoubleClick")
		;MsgBox ,,,%A_GuiControlEvent%, 1
return

ButtonAuthorize:
	; ==================== Get pass from bd for authorize ==========================
	GuiControlGet, APass
	SQL := "SELECT * FROM Users;"
	DB.GetTable(SQL, Result)
	SQLStr := ""
	_SQL := ""
	row1 := ""
	row2 := ""
	lpcounter := Result.RowCount
	Loop %lpcounter% {
		IdUsers := Result.Rows[A_Index, 1]
		PasswordUsers := Result.Rows[A_Index, 2]
		if (APass == PasswordUsers){
			CurrentIdUser := IdUsers
			authorized := 1
			Gosub RefreshBoxes
			Gosub MenuMain
			break
		}
	}
	if (authorized == 0)
		if(lang == lang2)
			MsgBox ,,,Неверный пароль., 1
		else
			MsgBox ,,,Invalid password., 1
return

ButtonNewUser:
	Gosub MenuNewUser
return

2ButtonBack:
	Gosub MenuAuthorize
return

2ButtonCreateNewUser:
	; ==================== Insert pass to the bd after creating new user ==========================
	GuiControlGet, NPass
	if(NPass != NULL){
		DB.Exec("BEGIN TRANSACTION;")
		SQLStr := ""
		_SQL := "INSERT INTO Users('Password') VALUES('Password#');"
		StringReplace, SQL, _SQL, Password#, %NPass%, All
		SQLStr .= SQL
		If !DB.Exec(SQLStr)
		   MsgBox, 16, SQLite Error, % "Msg:`t" . DB.ErrorMsg . "`nCode:`t" . DB.ErrorCode, 1
		DB.Exec("COMMIT TRANSACTION;")
		SQLStr := ""
		Gosub MenuAuthorize
	}
	else{
		if(lang == lang2)
			MsgBox ,,,Вы не ввели пароль., 1
		else
			MsgBox ,,,You have not entered a password., 1
	}
return

3ButtonNewAccount:
	;Control, Choose, 1, ComboBox1, PassManager.ahk
	Gosub MenuNewAccount
return

3ButtonDelete:
	Gui 3: Submit, Nohide
	GuiControlGet, SUpDown
	;MsgBox % ASAccAccId[SUpDown]
	SQLStr := ""
	_SQL := "DELETE FROM Information WHERE AccId = AccId#;"
	StringReplace, SQL, _SQL, AccId#, % ASAccAccId[SUpDown], All
	If !DB.Exec(SQL)
	   MsgBox, 16, SQLite Error, % "Msg:`t" . DB.ErrorMsg . "`nCode:`t" . DB.ErrorCode, 1
	Gosub RefreshBoxes
	ControlShowGUI("Hide")
return

4ButtonAddNewAccount:
	Gui, Submit, nohide
	if(AccNameApp == NULL){
		if(lang == lang2)
			MsgBox ,,,Вы не ввели имя., 1
		else
			MsgBox ,,,You have not entered a name, 1
	}
	else{
		; ==================== Get types from bd after adding new account ==========================
		SQL := "SELECT * FROM Types;"
		DB.GetTable(SQL, Result)
		SQLStr := ""
		_SQL := ""
		row1 := ""
		row2 := ""
		lpcounter := Result.RowCount
		if(AccTypeId == "Сайты")
			AccTypeId := "Sites"
		if(AccTypeId == "Приложения")
			AccTypeId := "Applications"
		if(AccTypeId == "Другое")
			AccTypeId := "Other"
		Loop %lpcounter% {
			IdTypes := Result.Rows[A_Index, 1]
			NameTypeTypes := Result.Rows[A_Index, 2]
			;GuiControl 3: , MenuTabName, %NameTypeTypes%
			if (AccTypeId == NameTypeTypes){
				AccTypeId := IdTypes
				break
			}
		}
		; ==================== Insert information to the bd after adding new account ==========================
		DB.Exec("BEGIN TRANSACTION;")
		SQLStr := ""
		_SQL := "INSERT INTO Information('UserId', 'TypeId', 'NameApp', 'UserName', 'Login', 'Password', 'Mail', 'Notes') VALUES('UserId#', 'TypeId#', 'NameApp#', 'UserName#', 'Login#', 'Password#', 'Mail#', 'Notes#');"
		StringReplace, SQL, _SQL, UserId#, %CurrentIdUser%, All
		StringReplace, SQL, SQL, TypeId#, %AccTypeId%, All
		StringReplace, SQL, SQL, NameApp#, %AccNameApp%, All
		StringReplace, SQL, SQL, UserName#, %AccUserName%, All
		StringReplace, SQL, SQL, Login#, %AccLogin%, All
		StringReplace, SQL, SQL, Password#, %AccPassword%, All
		StringReplace, SQL, SQL, Mail#, %AccMail%, All
		StringReplace, SQL, SQL, Notes#, %AccNotes%, All
		SQLStr .= SQL
		If !DB.Exec(SQLStr)
		   MsgBox, 16, SQLite Error, % "Msg:`t" . DB.ErrorMsg . "`nCode:`t" . DB.ErrorCode, 1
		DB.Exec("COMMIT TRANSACTION;")
		SQLStr := ""
		; ==================== Quick input after adding new account ==========================
		;MsgBox AccNameApp
		if AccNameApp not in %FullAccNameApp%
		{
			if (AccNameApp != NULL){
				if (AccTypeId == 1)
					GuiControl 3: , ListBoxFirst, %AccNameApp%
				if (AccTypeId == 2)
					GuiControl 3: , ListBoxSecond, %AccNameApp%
				if (AccTypeId == 3)
					GuiControl 3: , ListBoxThird, %AccNameApp%
				GuiControl 3: , ListBoxAll, %AccNameApp%
				;MsgBox %NameAppInformation%, %FullAccNameApp%, %A_Index%, %lpcounter%
				GuiControl 4: , AccNameApp, %AccNameApp%
				FullAccNameApp .= AccNameApp . ","
			}
		}
		if AccUserName not in %FullAccUserName%
		{
			if (AccUserName != NULL){
				GuiControl 4: , AccUserName, %AccUserName%
				FullAccUserName .= AccUserName . ","
			}
		}
		if AccLogin not in %FullAccLogin%
		{
			if (AccLogin != NULL){
				GuiControl 4: , AccLogin, %AccLogin%
				FullAccLogin .= AccLogin . ","
			}
		}
		if AccMail not in %FullAccMail%
		{
			if (AccMail != NULL){
				GuiControl 4: , AccMail, %AccMail%
				FullAccMail .= AccMail . ","
			}
		}
		ControlShowGUI("Hide")
		Gosub RefreshBoxes
		Gosub MenuMain
	}
return

4ButtonBack:
	ControlShowGUI("Hide")
	Gosub MenuMain
return
;=============================	END ======================================