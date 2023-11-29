#include "NW_I0_GENERIC"
#include "our_constants"
#include "our_functions"

// Called every time that the AI needs to take a combat decision. The default is
// a call to the NWN DetermineCombatRound.
void T2_DetermineCombatRound(object oIntruder = OBJECT_INVALID, int nAI_Difficulty = 10) {
	EquipCorrectWeapon();
	DoHealing(TRUE);
	ActionDoCommand(DetermineCombatRound(oIntruder, nAI_Difficulty));
	GoToMyTarget();
}

// Called every heartbeat (i.e., every six seconds).
void T2_HeartBeat() {
	if (GetIsInCombat()) return;
	DoHealing();
	SetNewTargetIfNeeded("smart");
	GoToMyTarget();
	HandleTelemetry();
}

// Called when the NPC is spawned.
void T2_Spawn() {
	SetNewTargetIfNeeded("smart");
	GoToMyTarget();
	HandleTelemetry();
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
