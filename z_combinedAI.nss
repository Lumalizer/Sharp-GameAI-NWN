#include "NW_I0_GENERIC"
#include "our_constants"

float T2_GetCreatureThreatLevel(object oCreature) {
	int isFriendly = SameTeam(oCreature, OBJECT_SELF);
	int inCombat = GetIsInCombat(oCreature);
	int isMaster = IsMaster(oCreature);
	int isFighter = IsFighter(oCreature);
	int isCleric = IsCleric(oCreature);
	int isWizard = IsWizard(oCreature);

	float fThreat = 1 * isCleric + 1.1 * isWizard + 1.4 * isFighter + 1.7 * isMaster;
	if (isFriendly) fThreat *= -1.0;
	if (inCombat) fThreat *= 1.2;
	if (!isFriendly && inCombat) fThreat += 0.1;
	int health = GetHealth(oCreature);
	fThreat = fThreat * ((health + 1) / 6.0);

	return fThreat;
}

float T2_GetLocationThreatLevel(string loc) {
	object oLocation = GetObjectByTag(loc);
	float fThreatLevel = 0.0;

	// check all creatures in the area
	int i = 1;
	object oCreature = GetNearestObjectToLocation(OBJECT_TYPE_CREATURE, GetLocation(oLocation), i);
	while (GetIsObjectValid(oCreature)) {
		float fDistance = GetDistanceBetween(oCreature, oLocation);
		if (fDistance > 30.0) break;
		fThreatLevel += T2_GetCreatureThreatLevel(oCreature);
		++i;
		if (i > 12) break;
		oCreature = GetNearestObjectToLocation(OBJECT_TYPE_CREATURE, GetLocation(oLocation), i);
	}

	return fThreatLevel;
}

string T2_GetNotSoRandomTarget() {
	if (IsWizardLeft(OBJECT_SELF))
		return WpClosestAltarLeft();
	else if (IsWizardRight(OBJECT_SELF))
		return WpClosestAltarRight();

	int iTarget = 0;

	if (IsMaster(OBJECT_SELF))
		iTarget = Random(8);
	else
		iTarget = Random(10);

	if (iTarget < 4)
		return WpDoubler();
	else if (iTarget < 6)
		return WpFurthestAltarLeft();
	else if (iTarget < 8)
		return WpFurthestAltarRight();
	else {
		int iTarget = Random(2);
		if (iTarget == 0)
			return WpClosestAltarLeft();
		else
			return WpClosestAltarRight();
	}
	return "";
}

void T2_DoHealing(int combat = FALSE) {
	int myHealth = GetHealth(OBJECT_SELF);

	if ((combat && myHealth < 4) || (!combat && myHealth < 5)) {
		if (TalentHealingSelf()) {
			// SpeakString("I am healing myself.", TALKVOLUME_SHOUT);
			return;
		}
	}

	if (TalentHeal()) {
		// SpeakString("I am healing.", TALKVOLUME_SHOUT);
		return;
	}
}

string T2_GetSmartAltar() {
	string sMyColor = MyColor();
	string sOpponentColor = OpponentColor();
	float ourThreat = T2_GetCreatureThreatLevel(OBJECT_SELF);

	int isMaster = IsMaster();
	int isFighter = IsFighter();
	int isCleric = IsCleric();
	int isWizard = IsWizard();

	string c_AL = WpClosestAltarLeft();
	string c_AR = WpClosestAltarRight();
	string f_AL = WpFurthestAltarLeft();
	string f_AR = WpFurthestAltarRight();
	string d = WpDoubler();

	string claimerC_AL = ClaimerOf(c_AL);
	string claimerC_AR = ClaimerOf(c_AR);
	string claimerF_AL = ClaimerOf(f_AL);
	string claimerF_AR = ClaimerOf(f_AR);
	string claimerD = ClaimerOf(d);

	float distanceC_AL = GetDistanceBetween(OBJECT_SELF, GetObjectByTag(c_AL));
	float distanceC_AR = GetDistanceBetween(OBJECT_SELF, GetObjectByTag(c_AR));
	float distanceF_AL = GetDistanceBetween(OBJECT_SELF, GetObjectByTag(f_AL));
	float distanceF_AR = GetDistanceBetween(OBJECT_SELF, GetObjectByTag(f_AR));
	float distanceD = GetDistanceBetween(OBJECT_SELF, GetObjectByTag(d));

	float fThreat_c_AL = T2_GetLocationThreatLevel(c_AL);
	float fThreat_c_AR = T2_GetLocationThreatLevel(c_AR);
	float fThreat_f_AL = T2_GetLocationThreatLevel(f_AL);
	float fThreat_f_AR = T2_GetLocationThreatLevel(f_AR);
	float fThreat_d = T2_GetLocationThreatLevel(d);

	string target = "";
	string targetReason = "";

	// class-specific behavior
	if (isWizard) {
		if (distanceC_AL < distanceC_AR && claimerC_AL != sMyColor)
			target = c_AL;
		else if (claimerC_AR != sMyColor)
			target = c_AR;
		else if (claimerC_AL != sMyColor)
			target = c_AL;

		if (target != "") targetReason = "(wizard target)";

	} else if (isMaster) {
		if (claimerD == sOpponentColor) target = d;
		if (target != "") targetReason = "(master target)";
	}

	// control close unclaimed altars
	if (target == "") {
		if (claimerD == "" && distanceD < 20.0)
			target = d;
		else if (claimerC_AL == "" && distanceC_AL < 20.0)
			target = c_AL;
		else if (claimerC_AR == "" && distanceC_AR < 20.0)
			target = c_AR;
		else if (claimerF_AL == "" && distanceF_AL < 20.0)
			target = f_AL;
		else if (claimerF_AR == "" && distanceF_AR < 20.0)
			target = f_AR;

		if (target != "") targetReason = "(unclaimed close target)";
	}

	// send cleric/fighter to doubler if needed
	if (IsClericLeft() || IsFighterRight()) {
		if (claimerD != sMyColor && fThreat_d < 3.0) target = d;
		if (target != "") targetReason = "(cleric/fighter to doubler)";
	}

	// threat level based decisions
	if (target == "") {
		int threat_decision_d = (fThreat_d >= 0.0 && fThreat_d + ourThreat < 1.3);
		int threat_decision_c_AL = (fThreat_c_AL > 0.0 && fThreat_c_AL + ourThreat < 0.4);
		int threat_decision_c_AR = (fThreat_c_AR > 0.0 && fThreat_c_AR + ourThreat < 0.4);
		int threat_decision_f_AL = (fThreat_f_AL > 0.0 && fThreat_f_AL + ourThreat < 0.3);
		int threat_decision_f_AR = (fThreat_f_AR > 0.0 && fThreat_f_AR + ourThreat < 0.3);

		if (threat_decision_d)
			target = d;
		else if (threat_decision_c_AL && threat_decision_c_AR) {
			if (distanceC_AL < distanceC_AR)
				target = c_AL;
			else
				target = c_AR;
		} else if (threat_decision_c_AL)
			target = c_AL;
		else if (threat_decision_c_AR)
			target = c_AR;
		else if (threat_decision_f_AL && threat_decision_f_AR) {
			if (distanceF_AL < distanceF_AR)
				target = f_AL;
			else
				target = f_AR;
		} else if (threat_decision_f_AL)
			target = f_AL;
		else if (threat_decision_f_AR)
			target = f_AR;

		if (target != "") targetReason = "(threat target)";
	}

	// control unclaimed altars
	if (target == "") {
		if (claimerD == "" && distanceD < 20.0)
			target = d;
		else if (claimerC_AL == "" && distanceC_AL < 20.0)
			target = c_AL;
		else if (claimerC_AR == "" && distanceC_AR < 20.0)
			target = c_AR;
		else if (claimerF_AL == "" && distanceF_AL < 20.0)
			target = f_AL;
		else if (claimerF_AR == "" && distanceF_AR < 20.0)
			target = f_AR;
		else if (claimerD == "" && distanceD < 35.0)
			target = d;
		else if (claimerC_AL == "" && distanceC_AL < 35.0)
			target = c_AL;
		else if (claimerC_AR == "" && distanceC_AR < 35.0)
			target = c_AR;
		else if (claimerF_AL == "" && distanceF_AL < 35.0)
			target = f_AL;
		else if (claimerF_AR == "" && distanceF_AR < 35.0)
			target = f_AR;
		else if (claimerD == "" && distanceD < 65.0)
			target = d;
		else if (claimerC_AL == "" && distanceC_AL < 65.0)
			target = c_AL;
		else if (claimerC_AR == "" && distanceC_AR < 65.0)
			target = c_AR;
		else if (claimerF_AL == "" && distanceF_AL < 65.0)
			target = f_AL;
		else if (claimerF_AR == "" && distanceF_AR < 65.0)
			target = f_AR;

		if (target != "") targetReason = "(unclaimed target)";
	}

	// random target if all else fails
	if (target == "") {
		target = T2_GetNotSoRandomTarget();
		targetReason = "(random Target) ";
	}

	float locationThreat = T2_GetLocationThreatLevel(target);
	float locationDistance = GetDistanceBetween(OBJECT_SELF, GetObjectByTag(target));
	string sMessage = target + ": " + targetReason +
					  " Threat score:" + FloatToString(locationThreat) +
					  " Distance:" + FloatToString(locationDistance);

	SetLocalString(OBJECT_SELF, "targetchoiceinfo", sMessage);

	return target;
}

int T2_DetermineNeedNewTarget() {
	string sTarget = GetLocalString(OBJECT_SELF, "TARGET");
	if (sTarget == "") {
		SetLocalString(OBJECT_SELF, "targetchangereason", "(no target)");
		return TRUE;
	}

	object oTarget = GetObjectByTag(sTarget);
	object oCreature = GetNearestObjectToLocation(OBJECT_TYPE_CREATURE, GetLocation(oTarget));
	float fToTarget = GetDistanceToObject(oTarget);
	int underOurControl = ClaimerOf(sTarget) == MyColor(OBJECT_SELF);

	if (IsMaster() && underOurControl) {
		SetLocalString(OBJECT_SELF, "targetchangereason", "(master should move on)");
		return TRUE;
	}

	// if I am the closest to the target, then do not choose a new target
	if (oCreature == OBJECT_SELF) return FALSE;

	// if enemy strength is too high, then choose a new target
	if (T2_GetLocationThreatLevel(sTarget) > 2.5) {
		SetLocalString(OBJECT_SELF, "targetchangereason", "(high enemy strength)");
		// SpeakString("Changing target (high enemy strength): " + sTarget, TALKVOLUME_SHOUT);
		return TRUE;
	};

	// if our strength is too high, then choose a new target
	if (T2_GetLocationThreatLevel(sTarget) < -2.5) {
		SetLocalString(OBJECT_SELF, "targetchangereason", "(high allied strength)");
		// SpeakString("Changing target (high enemy strength): " + sTarget, TALKVOLUME_SHOUT);
		return TRUE;
	};

	// If there is a member of my own team close to the target and closer than me,
	// and no enemy is closer and this other member is not in combat and
	// has the same target, then choose a new target.
	int i = 1;
	while (GetIsObjectValid(oCreature)) {
		if (GetLocation(oCreature) == GetLocation(OBJECT_SELF)) break;
		if (GetDistanceBetween(oCreature, oTarget) > fToTarget) break;
		if (GetDistanceBetween(oCreature, oTarget) > 5.0) break;
		if (!SameTeam(oCreature)) break;
		if (GetIsInCombat(oCreature)) break;
		if (GetLocalString(oCreature, "TARGET") == sTarget && !IsMaster(oCreature)) {
			SetLocalString(OBJECT_SELF, "targetchangereason", "(friendly has control)");
			return TRUE;
			break;
		}
		++i;
		oCreature = GetNearestObjectToLocation(OBJECT_TYPE_CREATURE, GetLocation(oTarget), i);
	}
	return FALSE;
}

// sets a new target, if needed, and returns the distance to the target
int T2_SetNewTargetIfNeeded(string method = "random") {
	if (!T2_DetermineNeedNewTarget()) return FALSE;

	string sTarget = "";

	if (method == "random")
		sTarget = T2_GetNotSoRandomTarget();
	else if (method == "smart")
		sTarget = T2_GetSmartAltar();

	if (method != "smart") {
		float locationThreat = T2_GetLocationThreatLevel(sTarget);
		string sMessage = "Going to: " + sTarget + " Threat score:" + FloatToString(locationThreat);
		// SpeakString(sMessage, TALKVOLUME_SHOUT);
	}

	// check if the new target is the same as the old target
	string pTarget = GetLocalString(OBJECT_SELF, "TARGET");
	if (pTarget == sTarget) return FALSE;

	SetLocalString(OBJECT_SELF, "oldtarget", pTarget);
	SetLocalString(OBJECT_SELF, "TARGET", sTarget);

	ClearAllActions(FALSE);

	return TRUE;
}

object T2_GetClosestEnemy() {
	object oEnemy =
		GetNearestCreature(CREATURE_TYPE_REPUTATION, REPUTATION_TYPE_ENEMY, OBJECT_SELF);
	return oEnemy;
}

int T2_IsEquippedWeaponMelee(object oCharacter) {
	object oWeapon = GetItemInSlot(INVENTORY_SLOT_RIGHTHAND, oCharacter);
	int iWeaponType = GetBaseItemType(oWeapon);

	// Check if the weapon type is melee
	if (iWeaponType == BASE_ITEM_LONGSWORD || iWeaponType == BASE_ITEM_SHORTSWORD ||
		iWeaponType == BASE_ITEM_DAGGER || iWeaponType == BASE_ITEM_MORNINGSTAR ||
		iWeaponType == BASE_ITEM_GREATSWORD || iWeaponType == BASE_ITEM_HALBERD ||
		iWeaponType == BASE_ITEM_SCIMITAR || iWeaponType == BASE_ITEM_BATTLEAXE ||
		iWeaponType == BASE_ITEM_HANDAXE || iWeaponType == BASE_ITEM_KAMA ||
		iWeaponType == BASE_ITEM_KUKRI || iWeaponType == BASE_ITEM_RAPIER ||
		iWeaponType == BASE_ITEM_SCYTHE || iWeaponType == BASE_ITEM_KATANA ||
		iWeaponType == BASE_ITEM_BASTARDSWORD || iWeaponType == BASE_ITEM_DIREMACE ||
		iWeaponType == BASE_ITEM_DOUBLEAXE || iWeaponType == BASE_ITEM_TWOBLADEDSWORD) {
		return TRUE;
	}

	return FALSE;
}

void T2_EquipCorrectWeapon() {
	object closestEnemy = T2_GetClosestEnemy();
	float fToEnemy = GetDistanceToObject(closestEnemy);

	if (fToEnemy < 3.0 && !T2_IsEquippedWeaponMelee(OBJECT_SELF) && !IsWizard(OBJECT_SELF) &&
		!IsCleric(OBJECT_SELF)) {
		// SpeakString("I am switching to melee.", TALKVOLUME_SHOUT);
		ActionEquipMostDamagingMelee();
	}
}

int T2_GoToMyTarget() {
	// if an enemy is close
	object closestEnemy = T2_GetClosestEnemy();
	float fToEnemy = GetDistanceToObject(closestEnemy);

	if (fToEnemy < 8.0) {
		// attack enemy directly
		ClearAllActions(TRUE);
		// SetLocalString(OBJECT_SELF, "TARGET", "");
		ActionAttack(closestEnemy);
		// return TRUE;
	}

	string sTarget = GetLocalString(OBJECT_SELF, "TARGET");
	// if (sTarget == "") return FALSE;
	object oTarget = GetObjectByTag(sTarget);

	if (T2_IsEquippedWeaponMelee(OBJECT_SELF) && !IsWizard(OBJECT_SELF)) {
		if (fToEnemy < 6.0 && fToEnemy > 2.0) {
			// SpeakString("I am melee closing in." + FloatToString(fToEnemy), TALKVOLUME_SHOUT);
			oTarget = closestEnemy;
		}
	}

	if (!GetIsObjectValid(oTarget)) return FALSE;
	float fToTarget = GetDistanceToObject(oTarget);
	if (fToTarget > 0.5) ActionMoveToLocation(GetLocation(oTarget), TRUE);
	return fToTarget > 0.0;
}

void T2_HandleTelemetry(int enabled = TRUE) {
	if (!enabled) return;
	string targetchoiceinfo = GetLocalString(OBJECT_SELF, "targetchoiceinfo");
	string targetchangereason = GetLocalString(OBJECT_SELF, "targetchangereason");
	string oldtarget = GetLocalString(OBJECT_SELF, "oldtarget");

	if (targetchangereason != "") {
		string sMessage = "Target Changed from: " + oldtarget + " " + targetchangereason +
						  " To: " + targetchoiceinfo;
		// SpeakString(sMessage, TALKVOLUME_SHOUT);
		SetLocalString(OBJECT_SELF, "targetchangereason", "");
	}
}

// Called every time that the AI needs to take a combat decision. The default is
// a call to the NWN DetermineCombatRound.
void T2_DetermineCombatRound(object oIntruder = OBJECT_INVALID, int nAI_Difficulty = 10) {
	T2_EquipCorrectWeapon();
	T2_DoHealing(TRUE);
	ActionDoCommand(DetermineCombatRound(oIntruder, nAI_Difficulty));
	T2_GoToMyTarget();
}

// Called every heartbeat (i.e., every six seconds).
void T2_HeartBeat() {
	if (GetIsInCombat()) return;
	T2_DoHealing();
	T2_SetNewTargetIfNeeded("smart");
	T2_GoToMyTarget();
	T2_HandleTelemetry();
}

// Called when the NPC is spawned.
void T2_Spawn() {
	T2_SetNewTargetIfNeeded("smart");
	T2_GoToMyTarget();
	T2_HandleTelemetry();
}

// This function is called when certain events take place, after the standard
// NWN handling of these events has been performed.
void T2_UserDefined(int Event) {
	switch (Event) {
		// The NPC has just been attacked.
		case EVENT_ATTACKED:
			break;

		// The NPC was damaged.
		case EVENT_DAMAGED:
			break;

		// At the end of one round of combat.
		case EVENT_END_COMBAT_ROUND:
			break;

		// Every heartbeat (i.e., every six seconds).
		case EVENT_HEARTBEAT:
			T2_HeartBeat();
			break;

		// Whenever the NPC perceives a new creature.
		case EVENT_PERCEIVE:
			break;

		// When a spell is cast at the NPC.
		case EVENT_SPELL_CAST_AT:
			break;

		// Whenever the NPC's inventory is disturbed.
		case EVENT_DISTURBED:
			break;

		// Whenever the NPC dies.
		case EVENT_DEATH:
			break;

		// When the NPC has just been spawned.
		case EVENT_SPAWN:
			T2_Spawn();
			break;
	}

	return;
}

// Called when the fight starts, just before the initial spawning.
void T2_Initialize(string sColor) { SetTeamName(sColor, "Team-" + GetStringLowerCase(sColor)); }
