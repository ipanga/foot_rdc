import {mkdir, writeFile} from 'node:fs/promises';
import {fileURLToPath} from 'node:url';

// Public GETs on footrdc.com only. Writes the fixtures used by the API contract tests.
const site = 'https://footrdc.com/wp-json/';
const api = site + 'rdcfootball/v1/';
const season = 324; const past = 325; const club = 4;
const queries = {
  competitions: 'competitions', competition: 'competitions/1', seasons: 'seasons', current_season: 'competitions/1/seasons/current',
  stages_current: `stages?season_id=${season}`, stages_past: `stages?season_id=${past}`,
  groups_current: `groups?season_id=${season}`, groups_past: `groups?season_id=${past}`,
  teams_current: `teams?season_id=${season}&limit=100`, teams_past: `teams?season_id=${past}&limit=100`,
  standings_current: `standings?season_id=${season}&limit=100`, standings_past: `standings?season_id=${past}&limit=100`,
  upcoming: `matches/upcoming?season_id=${season}&limit=15`, finished: `matches/finished?season_id=${season}&limit=15`,
  today: `matches/today?season_id=${season}&limit=15`, live: `matches/live?season_id=${season}&limit=15`,
  finished_past: `matches/finished?season_id=${past}&limit=15`, awarded_past: `matches?season_id=${past}&status=awarded&limit=3`,
  postponed: `matches?season_id=${season}&status=postponed&limit=3`, match: 'matches/6476', events: 'matches/6476/events',
  team: `teams/${club}`, profile: `teams/${club}/profile`, team_news: `teams/${club}/news?limit=3`, next_match: `teams/${club}/next-match`,
  team_results: `teams/${club}/results?season_id=${season}&limit=5`, team_matches: `teams/${club}/matches?season_id=${season}&limit=5`,
  team_standings: `teams/${club}/standings?season_id=${season}`, squad: `teams/${club}/squad?season_id=${season}&limit=30`,
  squad_past: `teams/${club}/squad?season_id=${past}&limit=30`, players: `players?team_id=${club}&season_id=${season}&limit=5`, freshness: `seasons/${season}/freshness`,
};
const output = {};
for (const [key, path] of Object.entries(queries)) {
  const response = await fetch(api + path, {headers: {'user-agent': 'FootRDC-contract-capture'}});
  if (!response.ok) throw new Error(`${key}: HTTP ${response.status}`);
  output[key] = await response.json();
}
const player = output.squad[0]?.player_id;
if (player) output.player = await (await fetch(`${api}players/${player}`)).json();
const fields = 'id,date_gmt,slug,link,title,excerpt,author,featured_media,categories';
output.categories = (await (await fetch(`${site}wp/v2/categories?per_page=100&_fields=id,name,slug,count`)).json());
output.edito_posts = await (await fetch(`${site}wp/v2/posts?categories=47&per_page=2&_fields=${fields}`)).json();
if (/"(?:external_id|source|api_token|api_key|password|ruling_note|aliases)"\s*:/.test(JSON.stringify(output))) throw new Error('Private field in a public contract');
const dir = fileURLToPath(new URL('../test/fixtures/', import.meta.url));
await mkdir(dir, {recursive: true});
await writeFile(dir + 'production_contract.json', JSON.stringify({captured_at: new Date().toISOString(), origin: api, data: output}, null, 1) + '\n');
console.log(JSON.stringify({keys: Object.keys(output).length, teams: output.teams_current.length, standings: output.standings_current.length, squad: output.squad.length}));
