// ********************************************************************
//
// Menu Display Script 
//
// Menu command format
// string = menuidentifier | display navigate? TRUE/FALSE | menuMaintitle~subtitle1~subtitle2~subtitle3 | button1~button2~button3 {| fixedbutton1~fixedbutton2~fixedbutton3  optional}
// key = menuuser key
//
// Return is in the format
// "menuidentifier | item"
//
// menusDescription [menuchannel, key, menu & parent, return link, nav?,  titles, buttons, fixed buttons]
// menusActive      [menuchannel, menuhandle, time, page] 
//
// by SimonT Quinnell
//
// CHANGES
// 10/14/2010 - Timeout message now gets sent to the prim that called the menu, not LINK_THIS.  Also includes menuidentifier
// 11/29/2010 - Fixed Bug in RemoveUser function.  Thanks for Virtouse Lilienthal for pointing it out.
// 11/29/2010 - Tidied up a little and removed functions NewMenu and RemoveUser that are only called once
// 04/28/2014 - Clarified licence
// 03/20/2022 - ZNI CREATIONS: Updated to include a color menu
// 07/20/2023 - Aria's Creations: Updated to include a number input system
// 07/21/2023 - Aria's Creations: Updated to include a toggle for utility button appending.
//
// NOTE: This script is licenced using the Creative Commons Attribution-Share Alike 3.0 license
//
// ********************************************************************
#include "src/includes/common.lsl"


 
// ********************************************************************
// CONSTANTS
// ********************************************************************
 
// Link Commands
integer     LINK_MENU_DISPLAY = 300;
integer     LINK_MENU_CLOSE = 310; 
integer     LINK_MENU_RETURN = 320;
integer     LINK_MENU_TIMEOUT = 330;
integer     LINK_MENU_CHANNEL = 303; // Returns from the dialog module to inform what the channel is
integer     LINK_MENU_ONLYCHANNEL = 302; // Sent with a ident to make a channel. No dialog will pop up, and it will expire just like any other menu if input is not received. 
 
// Main Menu Details
string      BACK = "<<";
string      FOWARD = ">>";
string      MANUAL_ENTRY = ">manual<";
list        MENU_NAVIGATE_BUTTONS = [ " ", " ", "-exit-"];
float       MENU_TIMEOUT_CHECK = 10.0;
integer     MENU_TIMEOUT = 120;
integer     MAX_TEXT = 510;
list        NUMBER_PAD = ["1", "2", "3", "4", "5", "6", "7", "8", "9"];
//list        NUMBER_PAD = ["7", "8", "9", "4", "5", "6", "1", "2", "3"];
list        NUMBER_PAD_END_NO_RNG = ["C", "0", "Confirm"];
list        NUMBER_PAD_END_RNG = ["Random", "0", "Confirm"];

string g_sNumPadCode;

 
integer     STRIDE_DESCRIPTION = 14;
integer     STRIDE_ACTIVE = 4;
integer     DEBUG = FALSE;
 
// ********************************************************************
// Variables
// ********************************************************************
 
list    menusDescription;
list    menusActive;
 
 
// ********************************************************************
// Functions - General
// ********************************************************************
 
debug(string debug)
{
    if (DEBUG) llSay(DEBUG_CHANNEL,"DEBUG:"+llGetScriptName()+":"+debug+" : Free("+(string)llGetFreeMemory()+")");
}  
 
 
integer string2Bool (string test)
{
    if (test == "TRUE") return TRUE;
    else return FALSE;
}
 
// ********************************************************************
// Functions - Menu Helpers
// ********************************************************************
 
integer NewChannel()
{    // generates unique channel number
    integer channel;
 
    do channel = -(llRound(llFrand(999999)) + 99999);
    while (~llListFindList(menusDescription, [channel]));
 
    return channel;    
}
 
 
string  CheckTitleLength(string title)
{
    if (llStringLength(title) > MAX_TEXT) title = llGetSubString(title, 0, MAX_TEXT-1);
 
    return title;
}
 
 
list FillMenu(list buttons)
{   //adds empty buttons until the list length is multiple of 3, to max of 12
    integer i;
    list    listButtons;
 
    for(i=0;i<llGetListLength(buttons);i++)
    {
        string name = llList2String(buttons,i);
        if (llStringLength(name) > 24) name = llGetSubString(name, 0, 23);
        listButtons = listButtons + [name];
    }
 
    while (llGetListLength(listButtons) != 3 && llGetListLength(listButtons) != 6 && llGetListLength(listButtons) != 9 && llGetListLength(listButtons) < 12)
    {
        listButtons = listButtons + [" "];
    }
 
    buttons = llList2List(listButtons, 9, 11);
    buttons = buttons + llList2List(listButtons, 6, 8);
    buttons = buttons + llList2List(listButtons, 3, 5);    
    buttons = buttons + llList2List(listButtons, 0, 2); 
 
    return buttons;
}
 
RemoveMenu(integer channel, integer echo)
{
    integer index = llListFindList(menusDescription, [channel]);
 
    if (index != -1)
    {
        key     menuId = llList2Key(menusDescription, index+1);
        string  menuDetails = llList2String(menusDescription, index+2);
        integer menuLink = llList2Integer(menusDescription, index+3);
        menusDescription = llDeleteSubList(menusDescription, index, index + STRIDE_DESCRIPTION - 1);
        RemoveListen(channel);
 
        if (echo) llMessageLinked(menuLink, LINK_MENU_TIMEOUT, menuDetails, menuId);
    }
}
 
RemoveListen(integer channel)
{
    integer index = llListFindList(menusActive, [channel]);
    if (index != -1)
    {    
        llListenRemove(llList2Integer(menusActive, index + 1));
        menusActive = llDeleteSubList(menusActive, index, index + STRIDE_ACTIVE - 1);
    }
}
 
// ********************************************************************
// Functions - Menu Main
// ********************************************************************
 
DisplayMenu(key id, integer channel, integer page, integer iTextBox)
{
    string  menuTitle;
    list    menuSubTitles;
    list    menuButtonsAll;
    list    menuButtonsTextAll;
    list    menuButtons;
    list    menuButtonsText;    // This is companion menu text per-button
    list    menuNavigateButtons;
    list    menuFixedButtons;
 
    integer max = 12;
    
    // Populate values
    integer index = llListFindList(menusDescription, [channel]);

    integer iNumpad = 0;
    

    menuButtonsAll = llParseString2List(llList2String(menusDescription, index+6), ["~"], []);
    menuButtonsTextAll = llParseString2List(llList2String(menusDescription,index + 10), ["~"], []);
    integer noUtil = (llList2String(menusDescription, index+9) == "NOUTIL");

    BACK = llList2String(menusDescription, index+11);
    FOWARD = llList2String(menusDescription, index+12);
    MENU_NAVIGATE_BUTTONS = llParseString2List(llList2String(menusDescription, index+13), ["~"], []);


    if (llList2String(menusDescription, index+7) != "") menuFixedButtons = llParseString2List(llList2String(menusDescription, index+7), ["~"], []);
    
    if(llList2String(menuButtonsAll,0)=="colormenu" && llGetListLength(menuButtonsAll)==1){
        menuButtonsAll = ["Dark Blue", "Blue", "Red", "Dark Red", "Green", "Dark Green", "Black", "White", ">custom<"];
    }else if(llList2String(menuButtonsAll,0) == "numpadplz" && llGetListLength(menuButtonsAll) == 1)
    {
        iNumpad = 1;
        if(g_sNumPadCode == "")
            menuButtonsAll = NUMBER_PAD_END_RNG + NUMBER_PAD;
        else menuButtonsAll = NUMBER_PAD_END_NO_RNG + NUMBER_PAD;
    }

    if(!noUtil){

        // Set up the menu buttons
        if (llList2Integer(menusDescription, index+4)) menuNavigateButtons= MENU_NAVIGATE_BUTTONS;
        else if (llGetListLength(menuButtonsAll) > (max-llGetListLength(menuFixedButtons)) && !noUtil) menuNavigateButtons = [" ", " ", " "];
    }
     
    // FIXME: add sanity check for menu page
     
    max = max - llGetListLength(menuFixedButtons) - llGetListLength(menuNavigateButtons);
    integer     start = page*max;
    integer     stop = (page+1)*max - 1;
    
    if(!iTextBox && IsListOfIDs(menuButtonsAll))
    {
        integer x=0;
        integer xe = llGetListLength(menuButtonsAll);
        list lTitle=llParseString2List(llList2String(menusDescription, index+5),["~"],[]);
        string sTitle = llList2String(lTitle,0);

        for(x=0;x<xe;x++)
        {
            if(IsLikelyAvatarID(llList2String(menuButtonsAll,x))){

                menuButtonsText += [(string)x + ". " + SLURL(llList2String(menuButtonsAll, x))];

                menuButtonsAll[x] = (string)x;
            } else {
                if(IsLikelyUUID(llList2String(menuButtonsAll, x)))
                {
                    menuButtonsText += [(string)x + ". " + llKey2Name(llList2String(menuButtonsAll, x))];
                    menuButtonsAll[x] = (string)x;
                }
            }
        }
        lTitle[0] = sTitle;
        menusDescription[index+5] = llDumpList2String(lTitle,"~");
    }

    menuButtons = FillMenu(menuFixedButtons + llList2List(menuButtonsAll, start, stop));

    if(llGetListLength(menuButtonsTextAll) > 0) {
        menuButtonsText = llList2List(menuButtonsTextAll, start,stop);
        menuButtonsAll = numberRange(start,stop);

        integer x=0;
        integer endx = llGetListLength(menuButtonsText);
        for(x=0;x<endx;x++)
        {
            menuButtonsText = llListReplaceList(menuButtonsText, [llList2String(menuButtonsAll,x)+". " + llList2String(menuButtonsText,x)], x,x);
        }
    }
    
    // Generate the title
    list tempTitle = llParseString2List(llList2String(menusDescription, index+5), ["~"], []);
    menuTitle = llList2String(tempTitle,0);
    if (llGetListLength(tempTitle) > 1) menuSubTitles = llList2List(tempTitle, 1, -1);
    if (llGetListLength(menuSubTitles) > 0)
    {
        integer i;
        for(i=start;i<(stop+1);++i)
        {
            if (llList2String(menuSubTitles, i) != "") menuTitle += "\n"+llList2String(menuSubTitles, i);
        }
    }
    menuTitle = CheckTitleLength(menuTitle);
 
    if(!noUtil){

        // Add navigate buttons if necessary
        if (page > 0) menuNavigateButtons = llListReplaceList(menuNavigateButtons, [BACK], 0, 0);
        if (llGetListLength(menuButtonsAll) > (page+1)*max) menuNavigateButtons = llListReplaceList(menuNavigateButtons, [FOWARD], 2, 2); 
    }
 
    // Set up listen and add the row details
    integer menuHandle = llListen(channel, "", id, "");
    menusActive = [channel, menuHandle, llGetUnixTime(), page] + menusActive;
 
    llSetTimerEvent(MENU_TIMEOUT_CHECK);

    menuTitle += llDumpList2String(menuButtonsText, "\n") + sSetor(iNumpad,"\nNew Value: " + (string)g_sNumPadCode, "");
    integer strlen = llStringLength(menuTitle);
    //llSay(0, "Menu Content page length: "+(string)strlen);
    if(strlen > 512)
    {
        llSay(0, "Unaltered menu text:\n" + menuTitle);
    }
    // Display menu
    if(!iTextBox)
        llDialog(id, menuTitle, menuNavigateButtons + menuButtons, channel);
    else llTextBox(id, menuTitle, channel);
}

 
// ********************************************************************
// Event Handlers
// ********************************************************************  
 
default
{
    listen(integer channel, string name, key id, string message)
    {
        if (message == BACK) 
        { 
            integer index = llListFindList(menusActive, [channel]);
            integer page = llList2Integer(menusActive, index+3)-1;
            RemoveListen(channel);            
            DisplayMenu(id, channel, page, FALSE);
        }
        else if (message == FOWARD)
        { 
            integer index = llListFindList(menusActive, [channel]);
            integer page = llList2Integer(menusActive, index+3)+1;
            RemoveListen(channel);
            DisplayMenu(id, channel, page, FALSE);
        }else if(message == MANUAL_ENTRY)
        {
            integer index = llListFindList(menusActive, [channel]);
            integer page = llList2Integer(menusActive, index+3);
            RemoveListen(channel);
            DisplayMenu(id, channel, 0, TRUE);
        }
        else if (message == " ")
        { 
            integer index = llListFindList(menusActive, [channel]);
            integer page = llList2Integer(menusActive, index+3);
            RemoveListen(channel);
            DisplayMenu(id, channel, page, FALSE);
        }
        else 
        {
            integer index = llListFindList(menusDescription, [channel]);
            if(llList2String(menusDescription,index+6)=="colormenu")
            {
                switch(message)
                {
                    case "Dark Blue":
                    {
                        message = "<0,0,0.5>";
                        break;
                    }
                    case "Blue":
                    {
                        message = "<0,0,1>";
                        break;
                    }
                    case "Red":
                    {
                        message = "<1,0,0>";
                        break;
                    }
                    case "Dark Red":
                    {
                        message = "<0.5,0,0>";
                        break;
                    }
                    case ">custom<":
                    {
                        llTextBox(id, "Enter the color using the format: <R,G,B> including the brackets.", channel);
                        return;
                    }
                    case "Green":
                    {
                        message = "<0,1,0>";
                        break;
                    }
                    case "Dark Green":
                    {
                        message = "<0,0.5,0>";
                        break;
                    }
                    case "Black":
                    {
                        message = "<0,0,0>";
                        break;
                    }
                    case "White":
                    {
                        message = "<1,1,1>";
                        break;
                    }
                    default:
                    {
                        break;
                    }
                }
            } else if(llGetSubString(llList2String(menusDescription,index+6),0, 8) == "numpadplz")
            {
                integer iReturn = 0;
                switch(message)
                {
                    case "Random":
                    {
                        g_sNumPadCode = (string)llRound(llFrand(0xFFFFFF));
                        break;
                    }
                    case "C":
                    {
                        g_sNumPadCode = "";
                        break;
                    }
                    case "Confirm":
                    {
                        if(g_sNumPadCode == "")
                        {
                            iReturn = 1;
                            message = "-1";
                        }else {
                            iReturn = 1;
                            message = g_sNumPadCode;
                        }
                        g_sNumPadCode = "";
                        break;
                    }
                    default:
                    {
                        g_sNumPadCode += message;
                        break;
                    }
                }

                if(!iReturn)
                {
                    RemoveListen(channel);
                    DisplayMenu(id, channel, 0, FALSE);
                    return;
                }
            }

            list lButtonOpts = llParseString2List(llList2String(menusDescription, index+6), ["~"], []);
            integer iV = (integer)message;
            if(message == "0" || iV>0)
            {
                string sBtn = llList2String(lButtonOpts, iV);
                if(IsLikelyUUID(sBtn))
                    message = sBtn;
            }
            llMessageLinked(llList2Integer(menusDescription, index+3), LINK_MENU_RETURN, llList2Json(JSON_OBJECT, ["type", "menu_back", "id", llList2String(menusDescription, index+2), "extra", llList2String(menusDescription, index+8), "reply", message]), id);

            //llMessageLinked(llList2Integer(menusDescription, index+3), LINK_MENU_RETURN, llList2String(menusDescription, index+2)+"|"+message, id);
            RemoveMenu(channel, FALSE);
        }
    }
 
    link_message(integer senderNum, integer num, string message, key id) 
    {
        if (num == LINK_MENU_DISPLAY)
        {   // Setup New Menu
            list    temp = llParseStringKeepNulls(message, ["|"], []);
            integer iTextBox=0;
            if(llList2String(temp,3)=="")iTextBox = 1;
            integer channel = NewChannel();

            //llSay(0, "DIALOG DEBUG : \n[ Item Count : "+(string)llGetListLength(temp)+" ]\n[ Items : "+llDumpList2String(temp, "~")+" ]\n[ Raw Request : "+message+" ]");
 
            if (llGetListLength(temp) > 2)
            {
                menusDescription = [channel, id, llList2String(temp, 0), senderNum,  string2Bool(llList2String(temp, 1)), llList2String(temp, 2), llList2String(temp, 3), llList2String(temp, 4), llList2String(temp, 5), llList2String(temp, 6), llList2String(temp,7), llList2String(temp,8), llList2String(temp,9), llList2String(temp,10)] + menusDescription;

                //llSay(0, "DIALOG DEBUG : \n[ "+llDumpList2String(menusDescription, " ~ ")+" ]");

                DisplayMenu(id, channel, 0, iTextBox);
            }
            else llSay (DEBUG_CHANNEL, "ERROR in "+llGetScriptName()+": Dialog Script. Incorrect menu format");
        }
        else if (num == LINK_MENU_CLOSE)
        {    // Will remove all menus that have the user id.
             integer index_id = llListFindList(menusDescription, [id]);
 
             while (~index_id) 
             {
                 integer channel = llList2Integer(menusDescription, index_id-1);
                 RemoveMenu(channel, FALSE);
 
                 // Check for another menu by same user
                 index_id = llListFindList(menusDescription, [id]);
             }
        } else if(num == LINK_MENU_ONLYCHANNEL)
        {
            integer channel = NewChannel();
            integer handle = llListen(channel, "", "", "");
            menusActive = [channel, handle, llGetUnixTime(), 0] + menusActive;
            menusDescription = [channel, id, message, senderNum, 0, " ", " ", " "]+menusDescription;
            llMessageLinked(LINK_SET, LINK_MENU_CHANNEL, (string)channel, message);
        }
    }
 
    timer()
    {   // Check through timers and close if necessary
        integer i;
        list toRemove;
        integer currentTime = llGetUnixTime();
        integer length = llGetListLength(menusActive);   
 
        for(i=0;i<length;i+=STRIDE_ACTIVE)
        {
            if (currentTime - llList2Integer(menusActive, i+2) > MENU_TIMEOUT) toRemove = [llList2Integer(menusActive, i)] + toRemove;
        }
 
        length = llGetListLength(toRemove);
        if (length > 0)
        {
            for(i=0;i<length;i++)
            {
                RemoveMenu(llList2Integer(toRemove, i), TRUE);
            }
        }        
    }
}

/*

string BACK = "<<";
string FORWARD = ">>";
list MENU_NAVIGATE_BUTTONS = [" ", " ", "-exit-"];

Menu(key kAv, string sText, list lButtons, string sIdent, string sExtra, list lCompanionText)
{
    llMessageLinked(LINK_THIS, LINK_MENU_DISPLAY, llDumpList2String([sIdent, "TRUE", sText, llDumpList2String(lButtons, "~"), "", sExtra, "", llDumpList2String(lCompanionText, "~"), BACK, FORWARD, llDumpList2String(MENU_NAVIGATE_BUTTONS, "~")], "|"), kAv);
}

MenuNoUtility(key kAv, string sText, list lButtons, string sIdent, string sExtra, list lCompanionText)
{
    llMessageLinked(LINK_THIS, LINK_MENU_DISPLAY, llDumpList2String([sIdent, "TRUE", sText, llDumpList2String(lButtons, "~"), "", sExtra, "NOUTIL", llDumpList2String(lCompanionText, "~"), BACK, FORWARD, llDumpList2String(MENU_NAVIGATE_BUTTONS, "~")], "|"), kAv);
}

GetArbitraryData(key kAv, string sText, string sIdent, string sExtra){
    llMessageLinked(LINK_THIS, LINK_MENU_DISPLAY, llDumpList2String([sIdent, "FALSE", sText, "", "", sExtra, "", "", BACK, FORWARD, llDumpList2String(MENU_NAVIGATE_BUTTONS, "~")], "|"), kAv);
}

GetListenerChannel(string sIdent)
{
    llMessageLinked(LINK_THIS, LINK_MENU_ONLYCHANNEL, sIdent, sIdent);
}

NumberPad(key kAv, string sText, string sIdent, string sExtra)
{
    llMessageLinked(LINK_THIS, LINK_MENU_DISPLAY, llDumpList2String([sIdent, "TRUE", sText, "numpadplz", "", sExtra, "NOUTIL", "", BACK, FORWARD, llDumpList2String(MENU_NAVIGATE_BUTTONS, "~")], "|"), kAv);
}



link_message(integer s,integer n,string m,key i)
{
    if(n == LINK_MENU_CHANNEL)
    {
        if(i == "ident")
        {
            //channel = m
        }
    }else if(n == LINK_MENU_RETURN)
    {
        if(llJsonGetValue(m, ["type"]) == "menu_back")
        {
            string sIdent = llJsonGetValue(m,["id"]);
            key kAv = i;
            string sReply = llJsonGetValue(m,["reply"]);
            string sExtra = llJsonGetValue(m,["extra"]);
        }
    }
}


*/