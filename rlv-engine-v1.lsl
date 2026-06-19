integer RLV_CHANNEL = -1812221819;
integer MENU_CHANNEL;

list poseNames = ["Pose 1", "Pose 2", "Pose 3"];
list poseAnims = ["pose1", "pose2", "pose3"];

string currentAnim = "";
integer hasAnimPerms = FALSE;

key captive = NULL_KEY;
key controller = NULL_KEY;
key pendingCaptive = NULL_KEY;

list nearbyNames;
list nearbyKeys;

string SAFEWORD = "red";

sayRLV(key av, string cmd)
{
    string packet = (string)llGetKey() + "," + (string)av + "," + cmd;
    llOwnerSay("SEND: " + packet);
    llRegionSay(RLV_CHANNEL, packet);
}

integer canControl(key user)
{
    if (user == llGetOwner()) return TRUE;
    if (user == controller) return TRUE;
    return FALSE;
}

scanAvatars(key user)
{
    controller = user;
    nearbyNames = [];
    nearbyKeys = [];
    llSensor("", NULL_KEY, AGENT, 20.0, PI);
}

showMainMenu(key user)
{
    if (captive == NULL_KEY)
    {
        llDialog(user, "RLV Furniture Test", ["Capture"], MENU_CHANNEL);
    }
    else
    {
        llDialog(user, "RLV Furniture Test", ["Release", "Restrict", "Pose"], MENU_CHANNEL);
    }
}

captureAvatar(key av)
{
    pendingCaptive = av;

    sayRLV(av, "@sit:" + (string)llGetKey() + "=force");

    llOwnerSay("Attempting force-sit: " + llKey2Name(av));
    llOwnerSay("Controller: " + llKey2Name(controller));

    llSetTimerEvent(8.0);
}

applyRestrictions()
{
    if (captive == NULL_KEY) return;

    sayRLV(captive,
        "@unsit=n"
        + "|@tploc=n"
        + "|@tplm=n"
        + "|@tplure=n"
        + "|@sittp=n"
        + "|@accepttp=n"
        + "|@detach=n"
    );

    llOwnerSay("Restrictions applied.");
}

showPoseMenu(key user)
{
    llDialog(user, "Choose pose:", ["Pose 1", "Pose 2", "Pose 3", "Stop Pose", "Back"], MENU_CHANNEL);
}

startPose(string poseButton)
{
    integer index = llListFindList(poseNames, [poseButton]);

    if (index == -1) return;
    if (captive == NULL_KEY) return;

    string anim = llList2String(poseAnims, index);

    if (currentAnim != "")
    {
        llStopAnimation(currentAnim);
    }

    llStartAnimation(anim);
    currentAnim = anim;

    llOwnerSay("Started pose: " + poseButton);
}

stopPose()
{
    if (currentAnim != "")
    {
        llStopAnimation(currentAnim);
        currentAnim = "";
    }

    llOwnerSay("Pose stopped.");
}

release()
{
    stopPose();

    if (captive != NULL_KEY)
    {
        sayRLV(captive, "!release");
        llOwnerSay("Released: " + llKey2Name(captive));
    }

    captive = NULL_KEY;
    pendingCaptive = NULL_KEY;
    controller = NULL_KEY;
    hasAnimPerms = FALSE;

    llSetTimerEvent(0.0);
}

finalizeCapture()
{
    key seated = llAvatarOnSitTarget();

    if (pendingCaptive != NULL_KEY && seated == pendingCaptive)
    {
        captive = pendingCaptive;
        pendingCaptive = NULL_KEY;

        llOwnerSay("Capture successful: " + llKey2Name(captive));

        applyRestrictions();

        llRegionSayTo(captive, 0, "Safeword is: " + SAFEWORD);
        llRegionSayTo(controller, 0, "Safeword is: " + SAFEWORD);

        llRequestPermissions(captive, PERMISSION_TRIGGER_ANIMATION);

        llSetTimerEvent(0.0);
    }
}

default
{
    state_entry()
    {
        MENU_CHANNEL = -1000000 - (integer)llFrand(1000000);

        llSitTarget(<0.0, 0.0, 0.5>, ZERO_ROTATION);
        llSetClickAction(CLICK_ACTION_SIT);

        llListen(0, "", NULL_KEY, "");
        llListen(MENU_CHANNEL, "", NULL_KEY, "");

        llOwnerSay("RLV Furniture Engine Ready.");
        llOwnerSay("Safeword is: " + SAFEWORD);
    }

    run_time_permissions(integer perm)
    {
        if (perm & PERMISSION_TRIGGER_ANIMATION)
        {
            hasAnimPerms = TRUE;
            llOwnerSay("Animation permissions granted.");
        }
    }

    touch_start(integer total)
    {
        key user = llDetectedKey(0);

        if (captive != NULL_KEY && !canControl(user) && user != captive)
        {
            llRegionSayTo(user, 0, "This furniture is locked by another controller.");
            return;
        }

        showMainMenu(user);
    }

    listen(integer channel, string name, key id, string msg)
    {
        if (channel == 0)
        {
            if (id == captive && llToLower(msg) == SAFEWORD)
            {
                llOwnerSay("Safeword used by " + llKey2Name(id));
                release();
            }

            return;
        }

        if (msg == "Capture")
        {
            scanAvatars(id);
        }
        else if (msg == "Pose")
        {
            if (canControl(id))
            {
                showPoseMenu(id);
            }
        }
        else if (msg == "Pose 1" || msg == "Pose 2" || msg == "Pose 3")
        {
            if (canControl(id) && hasAnimPerms)
            {
                startPose(msg);
            }
            else
            {
                llRegionSayTo(id, 0, "Animation permissions are not ready yet.");
            }
        }
        else if (msg == "Stop Pose")
        {
            if (canControl(id))
            {
                stopPose();
            }
        }
        else if (msg == "Back")
        {
            showMainMenu(id);
        }
        else if (msg == "Release")
        {
            if (canControl(id))
            {
                release();
            }
            else
            {
                llRegionSayTo(id, 0, "You are not allowed to release this furniture.");
            }
        }
        else if (msg == "Restrict")
        {
            if (canControl(id))
            {
                applyRestrictions();
            }
            else
            {
                llRegionSayTo(id, 0, "You are not allowed to control this furniture.");
            }
        }
        else
        {
            integer index = llListFindList(nearbyNames, [msg]);

            if (index != -1)
            {
                key av = llList2Key(nearbyKeys, index);

                if (captive == NULL_KEY && pendingCaptive == NULL_KEY)
                {
                    captureAvatar(av);
                }
                else
                {
                    llRegionSayTo(id, 0, "Furniture is already in use or capture is pending.");
                }
            }
        }
    }

    sensor(integer count)
    {
        integer i;

        for (i = 0; i < count && i < 12; i++)
        {
            nearbyNames += [llGetSubString(llDetectedName(i), 0, 23)];
            nearbyKeys += [llDetectedKey(i)];
        }

        llDialog(controller, "Choose avatar to force-sit:", nearbyNames, MENU_CHANNEL);
    }

    no_sensor()
    {
        llRegionSayTo(controller, 0, "No avatars nearby.");
    }

    timer()
    {
        finalizeCapture();

        if (pendingCaptive != NULL_KEY)
        {
            llOwnerSay("Capture failed. Avatar did not sit.");
            pendingCaptive = NULL_KEY;
            controller = NULL_KEY;
            llSetTimerEvent(0.0);
        }
    }

    changed(integer change)
    {
        if (change & CHANGED_LINK)
        {
            finalizeCapture();

            if (captive != NULL_KEY && llAvatarOnSitTarget() != captive)
            {
                release();
            }
        }
    }

    on_rez(integer p)
    {
        llResetScript();
    }
}