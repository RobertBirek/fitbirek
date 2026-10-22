"""Independent exact allowlist for the additive owner-equipment metadata field."""
from copy import deepcopy

REVIEWED_SETS = {
    'cw009': [['Masa własna', 'Step'], ['Masa własna', 'Krzesło'], ['Masa własna', 'Ławeczka']],
    'cw123': [['Wrist roller']],
    'cw135': [['Masa własna', 'Step'], ['Hantle', 'Step'], ['Hantle', 'Ławeczka']],
    'cw136': [['Masa własna', 'Step'], ['Hantle', 'Step'], ['Hantle', 'Ławeczka']],
    'cw165': [['Masa własna', 'Step'], ['Hantle', 'Step'], ['Hantle', 'Ławeczka']],
    'cw267': [['Ławeczka'], ['Roller']],
}


def before_owner_equipment(test, metadata):
    """Validate exact additions before projecting the unmodified historical hash."""
    result = deepcopy(metadata)
    actual = {eid: m['equipmentSets'] for eid, m in result['exercises'].items() if 'equipmentSets' in m}
    test.assertEqual(actual, REVIEWED_SETS)
    for eid in REVIEWED_SETS:
        del result['exercises'][eid]['equipmentSets']
    return result
