import { execSync, spawnSync } from 'node:child_process';
import { cpSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const tests = dirname(fileURLToPath(import.meta.url));
const app = resolve(tests, '../../app');
const options = { cwd: app, stdio: 'inherit' };

function run(command, args, runOptions) {
  const result = spawnSync(command, args, runOptions);
  if (result.error) throw result.error;
  if (result.status !== 0) {
    throw new Error(`${command} failed (${result.status ?? result.signal})`);
  }
}

function windowsFlutterRunner() {
  const { flutterRoot } = JSON.parse(
    execSync('flutter --version --machine', { cwd: app, encoding: 'utf8' }),
  );
  const tools = join(flutterRoot, 'packages', 'flutter_tools');
  const handler = join('lib', 'src', 'test', 'flutter_web_platform.dart');
  const source = readFileSync(join(tools, handler), 'utf8');
  const brokenPath = 'final String fullPath = _fileSystem.path.fromUri(request.url);';

  if (!source.includes(brokenPath)) {
    return {
      run: (args) => run(process.env.ComSpec ?? 'cmd.exe', ['/d', '/c', 'flutter', ...args], options),
      cleanup: () => {},
    };
  }

  // 3.47.5 converts this URL to a Windows path before matching a URL prefix.
  // Run a temporary Flutter tools copy so the installed SDK stays untouched.
  const scratch = mkdtempSync(join(tmpdir(), 'minifeed-flutter-web-test-'));
  const cleanup = () => {
    if (dirname(resolve(scratch)) === resolve(tmpdir())) {
      rmSync(scratch, { recursive: true, force: true });
    }
  };

  try {
    for (const entry of ['lib', 'bin', 'pubspec.yaml']) {
      cpSync(join(tools, entry), join(scratch, entry), { recursive: true });
    }
    const config = join('.dart_tool', 'package_config.json');
    mkdirSync(join(scratch, '.dart_tool'));
    cpSync(join(tools, config), join(scratch, config));
    writeFileSync(join(scratch, handler), source.replace(brokenPath, 'final String fullPath = request.url.path;'));

    const dart = join(flutterRoot, 'bin', 'cache', 'dart-sdk', 'bin', 'dart.exe');
    const entrypoint = join(scratch, 'bin', 'flutter_tools.dart');
    return {
      run: (args) => run(dart, [`--packages=${join(scratch, config)}`, entrypoint, ...args], {
        ...options,
        env: { ...process.env, FLUTTER_ROOT: flutterRoot },
      }),
      cleanup,
    };
  } catch (error) {
    cleanup();
    throw error;
  }
}

const flutter = process.platform === 'win32'
  ? windowsFlutterRunner()
  : { run: (args) => run('flutter', args, options), cleanup: () => {} };

try {
  for (const file of [
    'test/firestore_emulator_test.dart',
    'test/firestore_paging_emulator_test.dart',
    'test/firestore_like_emulator_test.dart',
    'test/firestore_comment_emulator_test.dart',
  ]) {
    // Replace the data before each suite, including when paging runs after writes.
    run(process.execPath, ['seed-repository-fixtures.mjs'], { cwd: tests, stdio: 'inherit' });
    flutter.run(['test', '--no-pub', '--platform', 'chrome', '--reporter', 'expanded', file]);
  }
} finally {
  flutter.cleanup();
}
