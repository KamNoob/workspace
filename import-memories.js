#!/usr/bin/env node

/**
 * import-memories.js
 * Imports memories from workspace files into Notion Memories database
 * Usage: node import-memories.js
 */

const fs = require('fs');
const path = require('path');

const NOTION_KEY = process.env.NOTION_KEY;
const DB_ID = '0b6460d8-3160-4e7e-b666-07070c7f4040';
const WORKSPACE = path.join(process.env.HOME || '/home/art', '.openclaw/workspace');

if (!NOTION_KEY) {
  console.error('Error: NOTION_KEY environment variable not set');
  process.exit(1);
}

async function notionRequest(method, endpoint, body = null) {
  const url = `https://api.notion.com/v1${endpoint}`;
  const options = {
    method,
    headers: {
      'Authorization': `Bearer ${NOTION_KEY}`,
      'Notion-Version': '2025-09-03',
      'Content-Type': 'application/json'
    }
  };
  
  if (body) {
    options.body = JSON.stringify(body);
  }

  try {
    const response = await fetch(url, options);
    if (!response.ok) {
      const error = await response.text();
      throw new Error(`${response.status}: ${error}`);
    }
    return await response.json();
  } catch (err) {
    console.error(`Notion API error: ${err.message}`);
    throw err;
  }
}

async function addMemory(title, category, content, sourceFile, date = null, importance = 'Medium', tags = []) {
  const properties = {
    'Memory': { title: [{ text: { content: title } }] },
    'Category': { select: { name: category } },
    'Content': { rich_text: [{ text: { content: content.substring(0, 2000) } }] },
    'Source': { rich_text: [{ text: { content: sourceFile } }] },
    'Importance': { select: { name: importance } }
  };

  if (date) {
    properties['Date'] = { date: { start: date } };
  }

  if (tags.length > 0) {
    properties['Tags'] = { multi_select: tags.map(t => ({ name: t })) };
  }

  try {
    await notionRequest('POST', '/pages', {
      parent: { database_id: DB_ID },
      properties
    });
    console.log(`✓ Added: ${title}`);
  } catch (err) {
    console.error(`✗ Failed: ${title} - ${err.message}`);
  }
}

async function parseMemoryFile(filePath, category, importance = 'Medium') {
  try {
    const content = fs.readFileSync(filePath, 'utf-8');
    const fileName = path.basename(filePath);
    
    // Extract date from filename
    const dateMatch = fileName.match(/(\d{4}-\d{2}-\d{2})/);
    const date = dateMatch ? dateMatch[1] : null;

    // Split by sections (##)
    const sections = content.split(/^##\s+/m);
    
    for (const section of sections) {
      const lines = section.trim().split('\n');
      if (lines.length === 0) continue;
      
      const title = lines[0].trim();
      const body = lines.slice(1).join('\n').trim();
      
      if (title && body && body.length > 10) {
        await addMemory(title, category, body, fileName, date, importance, ['Daily Note']);
      }
    }
  } catch (err) {
    console.error(`Error reading ${filePath}: ${err.message}`);
  }
}

async function importMemories() {
  console.log('🧠 Importing memories into Notion...\n');

  // Import long-term memory
  const memoryFile = path.join(WORKSPACE, 'MEMORY.md');
  if (fs.existsSync(memoryFile)) {
    console.log('📚 Importing MEMORY.md sections...');
    await parseMemoryFile(memoryFile, 'Long-term Knowledge', 'High');
  }

  // Import daily notes
  const memoryDir = path.join(WORKSPACE, 'memory');
  if (fs.existsSync(memoryDir)) {
    console.log('\n📅 Importing daily notes...');
    const files = fs.readdirSync(memoryDir)
      .filter(f => f.match(/^\d{4}-\d{2}-\d{2}.*\.md$/))
      .sort()
      .reverse()
      .slice(0, 10); // Last 10 days

    for (const file of files) {
      const filePath = path.join(memoryDir, file);
      console.log(`  → ${file}`);
      await parseMemoryFile(filePath, 'Daily Note', 'Medium');
    }
  }

  console.log('\n✅ Import complete!');
}

importMemories().catch(err => {
  console.error('Fatal error:', err);
  process.exit(1);
});
