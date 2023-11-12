
#define MASTER_CODE "6acaf07f"


integer ACCESS_OWNER = 1;
integer ACCESS_SELF_OWN = 2;
integer ACCESS_WEARER = 3;
integer ACCESS_GROUP = 4;
integer ACCESS_PUBLIC = 5;

integer ACCESS_NO_ACCESS = 99;

integer LM_CHECK_SETTINGS_READY = 11;
integer LM_SETTINGS_READY = 10;


string ToLevelString(integer level)
{
    string ret = "";
    switch(level)
    {
        case ACCESS_OWNER:
        {
            ret = "Owner";
            break;
        }
        case ACCESS_SELF_OWN:
        {
            ret = "Self Owner";
            break;
        }
        case ACCESS_WEARER:
        {
            ret = "Wearer";
            break;
        }
        case ACCESS_GROUP:
        {
            ret = "Group";
            break;
        }
        case ACCESS_PUBLIC:
        {
            ret = "Public";
            break;
        }
        default:
        {
            ret = "No Access";
            break;
        }
    }

    return ret;
}

writeSetting(string name, string value)
{
    llMessageLinked(LINK_SET, 0, llList2Json(JSON_OBJECT, ["cmd", "write_setting", "name", name, "value", value]), "");
}

readSetting(string name, string defaultValue)
{
    llMessageLinked(LINK_SET,0, llList2Json(JSON_OBJECT, ["cmd", "read_setting", "name",name, "default", defaultValue]), "");
}

deleteSetting(string name, string defaultValue)
{
    llMessageLinked(LINK_SET,0,llList2Json(JSON_OBJECT, ["cmd", "delete_setting", "name", name, "default", defaultValue]), "");
}


#define ARIA "5556d037-3990-4204-a949-73e56cd3cb06"



integer IsLikelyUUID(string sID)
{
    if(sID == (string)NULL_KEY)return TRUE;
    if(llStringLength(sID)==32)return TRUE;
    key kID = (key)sID;
    if(kID)return TRUE;
    if(llStringLength(sID) >25){
        if(llGetSubString(sID,8,8)=="-" && llGetSubString(sID, 13,13) == "-" && llGetSubString(sID,18,18) == "-" && llGetSubString(sID,23,23)=="-") return TRUE;

    }
    return FALSE;
}

integer IsLikelyAvatarID(key kID)
{
    if(!IsLikelyUUID(kID))return FALSE;
    // Avatar UUIDs always have the 15th digit set to a 4
    if(llGetSubString(kID,8,8) == "-" && llGetSubString(kID,14,14)=="4")return TRUE;

    return FALSE;
}

integer IsListOfIDs(list lIDs)
{
    integer i=0;
    integer end = llGetListLength(lIDs);
    for(i=0;i<end;i++){
        if(IsLikelyUUID(llList2String(lIDs,i)))return TRUE;
    }
    return FALSE;
}

integer bool(integer a){
    if(a)return TRUE;
    else return FALSE;
}
list g_lCheckboxes=["□","▣"];
string Checkbox(integer iValue, string sLabel) {
    return llList2String(g_lCheckboxes, bool(iValue))+" "+sLabel;
}

string sSetor(integer a, string b, string c)
{
    if(a)return b;
    else return c;
}
key kSetor(integer a, key b, key c)
{
    if(a)return b;
    else return c;
}
integer iSetor(integer a, integer b, integer c)
{
    if(a)return b;
    else return c;
}
vector vSetor(integer a, vector b, vector c)
{
    if(a)return b;
    else return c;
}
list lSetor(integer a,list b, list c)
{
    if(a)return b;
    else return c;
}

string Uncheckbox(string sLabel)
{
    integer iBoxLen = 1+llStringLength(llList2String(g_lCheckboxes,0));
    return llGetSubString(sLabel,iBoxLen,-1);
}


string SLURL(key kID){
    return "secondlife:///app/agent/"+(string)kID+"/about";
}
string OSLURL(key kID)
{
    return llKey2Name(kID); // TODO: Replace with a SLURL of some kind pointing to the object inspect.
}

list StrideOfList(list src, integer stride, integer start, integer end)
{
    list l = [];
    integer ll = llGetListLength(src);
    if(start < 0)start += ll;
    if(end < 0)end += ll;
    if(end < start) return llList2List(src, start, start);
    while(start <= end)
    {
        l += llList2List(src, start, start);
        start += stride;
    }
    return l;
}

string tf(integer a){
    if(a)return "true";
    return "false";
}

list g_lDSRequests;
key NULL=NULL_KEY;
UpdateDSRequest(key orig, key new, string meta){
    if(orig == NULL){
        g_lDSRequests += [new,meta];
    }else {
        integer index = HasDSRequest(orig);
        if(index==-1)return;
        else{
            g_lDSRequests = llListReplaceList(g_lDSRequests, [new,meta], index,index+1);
        }
    }
}

string GetDSMeta(key id){
    integer index=llListFindList(g_lDSRequests,[id]);
    if(index==-1){
        return "N/A";
    }else{
        return llList2String(g_lDSRequests,index+1);
    }
}

integer HasDSRequest(key ID){
    return llListFindList(g_lDSRequests, [ID]);
}

DeleteDSReq(key ID){
    if(HasDSRequest(ID)!=-1)
        g_lDSRequests = llDeleteSubList(g_lDSRequests, HasDSRequest(ID), HasDSRequest(ID)+1);
    else return;
}

string MkMeta(list lTmp){
    return llDumpList2String(lTmp, ":");
}
string SetMetaList(list lTmp){
    return llDumpList2String(lTmp, ":");
}

string SetDSMeta(list lTmp){
    return llDumpList2String(lTmp, ":");
}

list GetMetaList(key kID){
    return llParseStringKeepNulls(GetDSMeta(kID), [":"],[]);
}


key decodeAvatarInput(string sInput, string sExtra)
{
    if(IsLikelyAvatarID(sInput))
    {
        return (key)sInput;
    }else {
        list lParts = llParseString2List(sInput, ["/"],[]);
        if(llList2String(lParts,0) == "secondlife:")
        {
            return (key)llList2String(lParts,3);
        }else {
            UpdateDSRequest(NULL_KEY, llRequestUserKey(sInput), SetDSMeta(["decodeAvatar", sInput, sExtra]));
            return NULL_KEY;
        }
    }
}