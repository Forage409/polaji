import { readFileSync, readdirSync, statSync } from "node:fs";
import { extname, join, relative } from "node:path";
import { fileURLToPath } from "node:url";

const backendRoot = fileURLToPath(new URL("../", import.meta.url));
const sourceRoot = join(backendRoot, "src");
const failures = [];
let prepareCount = 0;

function walk(directory) {
    return readdirSync(directory).flatMap((entry) => {
        const path = join(directory, entry);
        return statSync(path).isDirectory() ? walk(path) : [path];
    });
}

function lineNumber(source, index) {
    return source.slice(0, index).split("\n").length;
}

function readStringLiteral(source, start) {
    const quote = source[start];
    if (!["'", '"', "`"].includes(quote)) return null;

    let escaped = false;
    for (let index = start + 1; index < source.length; index += 1) {
        const character = source[index];
        if (escaped) {
            escaped = false;
            continue;
        }
        if (character === "\\") {
            escaped = true;
            continue;
        }
        if (quote === "`" && character === "$" && source[index + 1] === "{") {
            return { error: "SQL template interpolation is forbidden", end: index };
        }
        if (character === quote) {
            return { end: index + 1 };
        }
    }
    return { error: "Unterminated SQL string literal", end: source.length };
}

for (const path of walk(sourceRoot).filter((file) => extname(file) === ".ts")) {
    const source = readFileSync(path, "utf8");
    const displayPath = relative(backendRoot, path).replaceAll("\\", "/");

    for (const match of source.matchAll(/\b(?:env\.)?DB\.exec\s*\(/g)) {
        failures.push(`${displayPath}:${lineNumber(source, match.index)} runtime DB.exec() is forbidden; use prepare().bind()`);
    }

    for (const match of source.matchAll(/\.prepare\s*\(/g)) {
        prepareCount += 1;
        let cursor = match.index + match[0].length;
        while (/\s/.test(source[cursor] ?? "")) cursor += 1;
        const literal = readStringLiteral(source, cursor);
        if (!literal) {
            failures.push(`${displayPath}:${lineNumber(source, match.index)} prepare() SQL must be a static string literal`);
            continue;
        }
        if (literal.error) {
            failures.push(`${displayPath}:${lineNumber(source, match.index)} ${literal.error}`);
        }
    }
}

if (failures.length > 0) {
    console.error("SQL parameterization audit failed:");
    for (const failure of failures) console.error(`- ${failure}`);
    process.exit(1);
}

console.log(`SQL parameterization audit passed: ${prepareCount} prepare() calls use static SQL literals.`);
