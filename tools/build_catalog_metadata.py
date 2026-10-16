#!/usr/bin/env python3
"""Build explicit offline metadata from reviewed ID decisions, never name guesses.

Legacy anatomy below was reviewed against both raw anatomical columns and the
movement instructions. A dash means no distinct supporting muscle, not unknown.
Stretches list their target muscles; a target need not be a contracting prime
mover. Broad 'Cardio', 'Full body', joint and coordination fields are resolved
per movement here. No such field is exposed as an anatomical category.
"""
import argparse
import json
from pathlib import Path

from catalog_additions import ADDITIONS

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / 'assets/data/exercise_catalog_metadata.json'

STYLES = [
    ('yoga', 'Joga', ['yoga']),
    ('tai_chi', 'Tai chi', ['taichi', 'tai-chi']),
    ('calisthenics', 'Kalistenika', ['calisthenics', 'street workout']),
    ('strength', 'Trening siłowy', ['strength', 'oporowy']),
    ('conditioning', 'Trening kondycyjny', ['cardio', 'kondycja']),
    ('mobility_recovery', 'Mobilność i regeneracja', ['mobility', 'rozciąganie', 'regeneracja']),
]
MUSCLES = [
    ('biceps', 'Biceps', ['dwugłowy ramienia']),
    ('triceps', 'Triceps', ['trójgłowy ramienia']),
    ('chest', 'Klatka piersiowa', ['piersiowe', 'pectoralis']),
    ('back', 'Plecy', ['latissimus dorsi', 'najszerszy grzbietu', 'trapezy', 'romboidy', 'prostowniki grzbietu']),
    ('shoulders', 'Barki', ['naramienne', 'deltoids']),
    ('abs', 'Brzuch', ['core', 'skośne brzucha', 'poprzeczny brzucha']),
    ('glutes', 'Pośladki', ['gluteus', 'pośladkowe', 'odwodziciele bioder']),
    ('quadriceps', 'Przód uda', ['kwadryceps', 'czworogłowy uda']),
    ('hamstrings', 'Tył uda', ['dwugłowy uda', 'kulszowo-goleniowe']),
    ('adductors', 'Przywodziciele uda', ['adduktory', 'wewnętrzna strona uda']),
    ('calves', 'Łydki', ['gastrocnemius', 'soleus', 'trójgłowy łydki']),
    ('forearms', 'Przedramiona', ['chwyt', 'grip', 'zginacze nadgarstka', 'prostowniki nadgarstka']),
    ('hip_flexors', 'Zginacze bioder', ['iliopsoas', 'biodrowo-lędźwiowy']),
    ('brachialis', 'Mięsień ramienny', ['brachialis', 'ramienny']),
    ('rotator_cuff', 'Stożek rotatorów barku', ['rotatory barku', 'infraspinatus', 'subscapularis', 'supraspinatus']),
    ('serratus', 'Mięsień zębaty przedni', ['serratus anterior']),
    ('tibialis_anterior', 'Przód goleni', ['piszczelowy przedni', 'tibialis anterior']),
    ('neck', 'Mięśnie szyi', ['zginacze szyi']),
    ('diaphragm', 'Przepona', ['diaphragm']),
    ('feet', 'Mięśnie stóp', ['stopy']),
    ('quadratus_lumborum', 'Mięsień czworoboczny lędźwi', ['QL', 'quadratus lumborum']),
]

# One reviewed row per ID: primary | supporting. Explicit, not runtime inference.
ANATOMY = '''
001 chest | triceps shoulders abs
002 triceps | chest shoulders
003 chest | shoulders triceps
004 chest | triceps abs shoulders
005 chest | triceps abs
006 chest | triceps shoulders
007 chest | shoulders triceps hip_flexors
008 chest | abs hip_flexors
009 chest | shoulders triceps
010 chest | triceps shoulders
011 chest | abs shoulders
012 chest | triceps shoulders
013 chest | shoulders triceps
014 chest | triceps
015 chest | triceps
016 chest | shoulders
017 chest | shoulders
018 chest | shoulders
019 chest back | triceps serratus
020 chest | glutes triceps
021 chest | triceps abs
022 chest | shoulders
023 chest | triceps shoulders abs
024 chest back | triceps
025 chest | triceps shoulders
026 chest | shoulders serratus abs
027 chest | forearms triceps
028 chest | triceps shoulders abs
029 chest | triceps abs
030 chest | shoulders triceps abs
031 back | biceps shoulders abs
032 biceps back | shoulders abs
033 back | biceps brachialis
034 back | biceps brachialis
035 back | biceps abs
036 back | biceps abs
037 back | abs hip_flexors biceps
038 back | biceps abs
039 back | biceps abs forearms
040 back | biceps
041 back | biceps abs forearms
042 back | biceps forearms
043 forearms | shoulders back abs
044 back | forearms
045 back | forearms
046 back | biceps shoulders abs
047 back | biceps shoulders
048 back | biceps shoulders
049 back | abs chest triceps
050 back | shoulders
051 back | biceps
052 back | abs biceps
053 back | -
054 back | forearms
055 shoulders back | -
056 back | biceps shoulders
057 back | biceps shoulders
058 shoulders back | rotator_cuff
059 back | glutes hamstrings
060 back | glutes
061 shoulders back | rotator_cuff
062 back | glutes hamstrings
063 hamstrings glutes | back
064 back | biceps shoulders
065 shoulders | triceps chest abs
066 shoulders | triceps abs glutes
067 shoulders | triceps rotator_cuff
068 shoulders | triceps chest
069 shoulders | triceps quadriceps glutes abs
070 shoulders | back
071 shoulders | abs calves feet
072 shoulders | back
073 shoulders | chest
074 shoulders | abs
075 shoulders | back
076 shoulders | back
077 back shoulders | rotator_cuff
078 shoulders | triceps chest
079 shoulders | triceps
080 shoulders | abs rotator_cuff forearms
081 shoulders | triceps abs
082 shoulders | triceps abs
083 shoulders | back
084 shoulders | abs
085 shoulders | rotator_cuff back
086 shoulders | rotator_cuff back
087 rotator_cuff | shoulders
088 rotator_cuff | chest
089 rotator_cuff shoulders | back
090 rotator_cuff | shoulders
091 rotator_cuff | shoulders
092 rotator_cuff | shoulders
093 biceps | brachialis forearms
094 biceps brachialis | forearms
095 biceps | brachialis
096 biceps | brachialis
097 biceps forearms | brachialis
098 biceps | brachialis
099 brachialis | biceps
100 forearms brachialis | biceps
101 biceps | brachialis
102 biceps | back
103 biceps | brachialis
104 biceps | brachialis
105 triceps | shoulders
106 triceps | shoulders
107 triceps | chest
108 triceps | chest shoulders
109 triceps | shoulders
110 triceps | chest
111 triceps | shoulders
112 triceps | shoulders
113 triceps | chest
114 triceps | forearms
115 triceps | shoulders
116 triceps | chest
117 forearms | -
118 forearms | -
119 forearms back | abs quadriceps glutes calves
120 forearms | shoulders back
121 forearms back | biceps
122 forearms | -
123 forearms | -
124 forearms | -
125 quadriceps glutes | abs back
126 quadriceps glutes | abs forearms
127 quadriceps glutes | abs chest shoulders
128 quadriceps glutes | hamstrings abs
129 quadriceps glutes | abs
130 quadriceps glutes | hamstrings abs
131 quadriceps glutes | hamstrings abs
132 quadriceps adductors | glutes abs
133 glutes | quadriceps adductors
134 quadriceps glutes | abs
135 quadriceps glutes | abs
136 quadriceps glutes | abs hip_flexors
137 quadriceps glutes | abs calves hip_flexors
138 quadriceps glutes | abs calves
139 quadriceps glutes | abs adductors
140 quadriceps | abs
141 quadriceps | glutes abs
142 quadriceps | glutes abs
143 quadriceps adductors | glutes
144 quadriceps glutes | abs calves
145 quadriceps glutes | abs calves
146 quadriceps glutes | hamstrings abs calves
147 quadriceps glutes | hamstrings abs calves
148 hamstrings glutes | back
149 hamstrings glutes | abs
150 hamstrings back | glutes
151 adductors glutes | quadriceps back
152 back hamstrings | glutes
153 hamstrings | glutes abs
154 glutes | hamstrings abs
155 glutes | hamstrings
156 glutes | hamstrings abs
157 glutes | hamstrings abs
158 glutes | adductors
159 glutes | abs hamstrings
160 glutes | -
161 glutes | -
162 glutes | abs
163 calves | feet
164 calves | feet
165 calves | feet
166 calves | feet
167 calves | feet
168 tibialis_anterior | feet
169 abs | shoulders glutes
170 abs | shoulders chest glutes
171 abs | glutes shoulders
172 abs | glutes shoulders
173 abs | glutes
174 abs | shoulders
175 abs shoulders | triceps chest
176 abs | back chest
177 abs glutes | shoulders
178 adductors | abs
179 abs | -
180 abs | -
181 abs back | glutes shoulders
182 abs | glutes shoulders
183 abs | hip_flexors
184 abs | hip_flexors
185 back | glutes shoulders
186 abs | hip_flexors
187 abs | hip_flexors
188 abs | -
189 abs | hip_flexors
190 abs | hip_flexors
191 abs | hip_flexors
192 abs | hip_flexors
193 abs | -
194 abs | -
195 abs | shoulders
196 abs | shoulders
197 abs | shoulders
198 abs quadratus_lumborum | -
199 abs | hip_flexors forearms
200 abs | hip_flexors forearms
201 abs | forearms
202 abs back | forearms hip_flexors
203 abs hip_flexors | forearms shoulders triceps
204 abs | back glutes hamstrings
205 abs | back shoulders
206 abs | forearms back
207 abs | forearms
208 abs hip_flexors | shoulders quadriceps
209 quadriceps glutes chest | abs shoulders triceps calves
210 chest triceps quadriceps glutes | abs shoulders calves
211 quadriceps glutes | abs chest shoulders calves
212 quadriceps glutes | abs shoulders
213 calves shoulders | glutes abs
214 quadriceps glutes calves | shoulders abs
215 hip_flexors | abs calves quadriceps
216 hamstrings | calves abs
217 abs | shoulders hip_flexors
218 abs | shoulders hip_flexors
219 quadriceps glutes | abs shoulders
220 quadriceps glutes | abs calves
221 quadriceps glutes | abs hip_flexors calves
222 quadriceps glutes | hamstrings abs calves
223 shoulders abs | quadriceps glutes triceps
224 triceps shoulders | abs glutes
225 calves | abs forearms
226 calves | abs
227 hip_flexors calves | abs
228 calves | abs feet
229 calves | abs
230 calves | abs
231 calves | forearms abs
232 calves | forearms shoulders
233 calves | forearms shoulders
234 quadriceps hamstrings glutes calves | abs hip_flexors
235 glutes calves quadriceps | abs hamstrings
236 quadriceps hamstrings glutes calves | abs hip_flexors
237 glutes hamstrings calves | quadriceps abs
238 quadriceps hamstrings glutes calves | abs hip_flexors
239 quadriceps hamstrings glutes calves | abs hip_flexors
240 quadriceps hamstrings glutes calves | abs hip_flexors
241 quadriceps glutes calves | hamstrings
242 shoulders | back
243 hip_flexors hamstrings | glutes abs
244 adductors glutes | abs
245 glutes hip_flexors | abs
246 hip_flexors back | quadriceps abs
247 hamstrings shoulders | abs calves
248 hip_flexors back | chest glutes hamstrings
249 hip_flexors | abs adductors
250 back | abs
251 back | chest
252 back | glutes shoulders
253 hamstrings glutes back shoulders | calves
254 back chest | hip_flexors
255 glutes | hip_flexors
256 glutes | adductors
257 adductors | glutes
258 adductors | glutes
259 adductors glutes | quadriceps
260 hip_flexors | quadriceps
261 quadriceps | hip_flexors
262 hamstrings | calves
263 hamstrings back | calves
264 calves | -
265 chest | shoulders
266 back | shoulders
267 back | chest
268 back | abs
269 neck | back
270 neck | -
271 shoulders | back
272 forearms | -
273 forearms | -
274 forearms | -
275 calves tibialis_anterior | feet
276 calves | tibialis_anterior
277 glutes adductors calves | quadriceps
278 shoulders | chest
279 shoulders | chest back
280 quadriceps hip_flexors | back
281 shoulders quadriceps glutes abs | hamstrings back chest triceps
282 chest | shoulders diaphragm
283 shoulders | back
284 shoulders | abs
285 shoulders back | abs
286 shoulders | abs
287 hip_flexors | abs
288 shoulders | abs
289 shoulders | back
290 back | abs
291 back | abs
292 back | hamstrings
293 glutes | -
294 quadratus_lumborum abs | shoulders
295 neck | back
296 shoulders | back
297 back shoulders | rotator_cuff
298 calves tibialis_anterior | feet
299 glutes hip_flexors | abs
300 diaphragm | -
301 diaphragm | -
302 quadriceps glutes shoulders | chest abs triceps
303 chest back quadriceps glutes shoulders | abs triceps
304 glutes hamstrings shoulders chest | abs triceps
305 glutes hamstrings shoulders | abs quadriceps triceps
306 glutes hamstrings shoulders | abs quadriceps
307 glutes hamstrings | abs shoulders
308 abs shoulders glutes | quadriceps triceps
309 quadriceps glutes biceps shoulders | abs triceps
310 back chest | abs triceps shoulders
311 quadriceps glutes biceps | abs
312 hamstrings glutes back | biceps
313 shoulders chest abs | glutes quadriceps triceps
314 quadriceps glutes shoulders | abs triceps
315 quadriceps glutes chest back | abs biceps triceps
316 forearms abs back | quadriceps glutes calves
'''


def numbers(text):
    """Parse reviewed inclusive ID ranges (not anatomical/name inference)."""
    result = set()
    for token in text.split():
        parts = token.split('-')
        result.update(range(int(parts[0]), int(parts[-1]) + 1))
    return result


TIME = numbers('43-44 60 80 119-120 122 141-142 169-171 178 183 185 203 206-208 213 215-218 223-230 232 234-235 238-241 251-265 273-274 277 279-280 283 285 287 290 292-295 297 301 316')
ROUNDS = numbers('236-237 281 300 313')
UNILATERAL = numbers('4-5 8 11 28 30 35 38-39 46 49-50 52 71 74 83 87-88 90 95 98-99 106 109 122 128-139 143 149 157 159-161 164 171-182 192-198 201 207 218 220 228 242-244 246 248-249 255-256 259-262 264-266 275-276 280 283-290 293-295 297-298 305-306 308 311')
CALISTHENICS = numbers('1-9 11 25-45 59-61 78-81 102 110-111 120-121 137-141 144-147 153-154 157-159 163 167-175 177-179 181-186 188-193 199-204 208-224 243-250 277 313 315')
YOGA = numbers('250-255 257-258 263 266 268 277 281 290-294 297')


def build() -> dict:
    exercises = {}
    for line in ANATOMY.strip().splitlines():
        left, right = line.split('|')
        number, *primary = left.split()
        n = int(number)
        styles = ['strength'] if n <= 208 or n >= 302 else []
        if n in CALISTHENICS:
            styles.append('calisthenics')
        if 209 <= n <= 240 or n >= 302:
            styles.append('conditioning')
        if 241 <= n <= 301:
            styles.append('mobility_recovery')
        if n in YOGA:
            styles.append('yoga')
        if 282 <= n <= 289:
            styles.append('tai_chi')
        exercises[f'cw{n:03d}'] = dict(
            styles=styles, primaryMuscles=primary,
            secondaryMuscles=[] if right.strip() == '-' else right.split(),
            aliases=['taichi siedzące'] if 282 <= n <= 289 else [],
            tracking='rounds' if n in ROUNDS else 'time' if n in TIME else 'reps',
            unilateral=n in UNILATERAL)
    for a in ADDITIONS:
        exercises[f'cw{a["number"]:03d}'] = dict(
            styles=a['style'], primaryMuscles=a['primary'], secondaryMuscles=a['secondary'],
            aliases=([a['en'], 'worek z piaskiem'] if a['equipment'] == 'Sandbag' else
                     [a['en'], 'ab wheel', 'ab roller'] if a['equipment'] == 'Kółko do brzucha' else [a['en']]),
            tracking=a['tracking'], unilateral=a['unilateral'])
    # Crow/frog stand belongs to both traditions: one record, two styles.
    exercises['cw357']['styles'].append('yoga')
    return dict(schemaVersion=1,
                styles=[dict(id=i, label=l, aliases=a) for i, l, a in STYLES],
                muscles=[dict(id=i, label=l, aliases=a) for i, l, a in MUSCLES],
                exercises=exercises)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    text = json.dumps(build(), ensure_ascii=False, indent=2) + '\n'
    if args.check:
        if OUTPUT.read_text() != text:
            raise ValueError('Metadata differs from reviewed classification')
        print('Metadata CHECK OK')
    else:
        OUTPUT.write_text(text, encoding='utf-8')
        print(f'Metadata: {len(build()["exercises"])} explicit entries')


if __name__ == '__main__':
    main()
