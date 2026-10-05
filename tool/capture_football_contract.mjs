import {mkdir, writeFile} from 'node:fs/promises';
import {fileURLToPath} from 'node:url';

// Public Core GETs only. Never reads account configuration or provider clients.
const origin = 'https://staging.sportrdc.com/wp-json/rdcfootball/v1/';
const queries = {
  competitions: 'competitions', seasons: 'seasons?competition_id=1',
  stages: 'stages?season_id=1', groups: 'groups?season_id=1',
  group_a_results: 'matches?season_id=1&stage_id=1&group_id=1&view=results&limit=25',
  group_b_results: 'matches?season_id=1&stage_id=1&group_id=2&view=results&limit=25',
  playoff_results: 'matches?season_id=1&stage_id=2&view=results&limit=25',
  teams: 'teams?limit=50', team: 'teams/12',
  results: 'teams/12/results?season_id=1&limit=5',
  schedule: 'teams/12/matches?season_id=1&limit=25',
  next: 'teams/12/next-match?season_id=1',
  standings: 'teams/12/standings?season_id=1',
  squad: 'teams/12/squad?season_id=1&limit=25',
  statistics: 'teams/12/statistics?season_id=1&limit=25',
  finished: 'matches/finished?competition_id=1&season_id=1&limit=25',
  finished_page2: 'matches/finished?competition_id=1&season_id=1&limit=25&page=2',
  today: 'matches/today?competition_id=1&season_id=1&limit=25',
  upcoming: 'matches/upcoming?competition_id=1&season_id=1&limit=25',
};
const output = {};
const timings = {};
for (const [key, path] of Object.entries(queries)) {
  const start = performance.now();
  const response = await fetch(origin + path);
  if (!response.ok) throw new Error(`Core contract ${key}: HTTP ${response.status}`);
  output[key] = await response.json();
  timings[key] = Math.round(performance.now()-start);
}
const match = output.finished[0]?.id;
if (!match) throw new Error('No representative finished match');
for (const [key, path] of [['match', `matches/${match}`], ['events', `matches/${match}/events`]]) {
  const start = performance.now();
  const response = await fetch(origin + path);
  if (!response.ok) throw new Error(`Core contract ${key}: HTTP ${response.status}`);
  output[key] = await response.json();
  timings[key] = Math.round(performance.now()-start);
}
const forbidden = /"(?:external_id|source|api_token|api_key|password|manual_override|ruling_note|conflict)"\s*:/;
if (forbidden.test(JSON.stringify(output))) throw new Error('Private fields in public contract');
const directory = fileURLToPath(new URL('../test/fixtures/', import.meta.url));
await mkdir(directory, {recursive:true});
await writeFile(directory + 'staging_core.json', JSON.stringify({
  captured_at: new Date().toISOString(), origin, elapsed_ms: timings, data: output,
}, null, 2) + '\n');
console.log(JSON.stringify({contracts:Object.keys(output).length, teams:output.teams.length,
  team:output.team.name, match, provider_api_requests:0}));
if (process.argv.includes('--images')) {
  const images = {};
  for (const url of new Set([output.team.logo_url,output.match.home_logo,output.match.away_logo])) {
    if (new URL(url).host !== 'cdn.sportmonks.com' || new URL(url).protocol !== 'https:') throw new Error('Unexpected public asset origin');
    const response = await fetch(url);
    if (!response.ok || !response.headers.get('content-type')?.startsWith('image/')) throw new Error('Public logo unavailable');
    images[url] = Buffer.from(await response.arrayBuffer()).toString('base64');
  }
  await writeFile(directory + 'public_logos.json', JSON.stringify(images, null, 2) + '\n');
  console.log(`Captured ${Object.keys(images).length} public static logos; provider API requests 0`);
}
