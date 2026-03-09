#!/usr/bin/env node

/**
 * Build Your Own X - Tutorial Index & Search
 * Queryable interface to 345+ tutorials for building technologies from scratch
 */

const fs = require('fs');
const path = require('path');

class BuildYourOwnXIndex {
  constructor() {
    const indexPath = path.join(__dirname, '../references/tutorials-index.json');
    this.data = JSON.parse(fs.readFileSync(indexPath, 'utf8'));
    this.categories = this.data.categories;
  }

  /**
   * List all categories
   */
  listCategories() {
    return Object.keys(this.categories).sort();
  }

  /**
   * Get tutorials for a category
   * @param {string} category - Category name (case-insensitive)
   * @returns {array} Tutorials in that category
   */
  getCategory(category) {
    const normalized = Object.keys(this.categories).find(
      c => c.toLowerCase() === category.toLowerCase()
    );
    return normalized ? this.categories[normalized] : null;
  }

  /**
   * Search tutorials by keyword
   * @param {string} query - Search query (title, language, or category)
   * @returns {array} Matching tutorials with metadata
   */
  search(query) {
    const q = query.toLowerCase();
    const results = [];

    Object.entries(this.categories).forEach(([category, tutorials]) => {
      tutorials.forEach(tutorial => {
        const matchCategory = category.toLowerCase().includes(q);
        const matchLanguage = tutorial.language.toLowerCase().includes(q);
        const matchTitle = tutorial.title.toLowerCase().includes(q);

        if (matchCategory || matchLanguage || matchTitle) {
          results.push({
            category,
            ...tutorial,
            _matchType: matchCategory ? 'category' : matchLanguage ? 'language' : 'title'
          });
        }
      });
    });

    return results;
  }

  /**
   * Get tutorials for a specific language
   * @param {string} language - Language name (e.g., "Python", "Go", "C++")
   * @returns {array} Tutorials in that language
   */
  getLanguage(language) {
    const q = language.toLowerCase();
    return this.search(q).filter(t => t.language.toLowerCase() === q);
  }

  /**
   * Get random tutorial for exploration
   * @returns {object} Random tutorial
   */
  getRandom() {
    const allTutorials = Object.entries(this.categories).flatMap(
      ([category, tutorials]) => tutorials.map(t => ({ category, ...t }))
    );
    return allTutorials[Math.floor(Math.random() * allTutorials.length)];
  }

  /**
   * Get statistics
   */
  getStats() {
    const allTutorials = Object.values(this.categories).flat();
    const languages = {};
    allTutorials.forEach(t => {
      languages[t.language] = (languages[t.language] || 0) + 1;
    });

    return {
      totalCategories: Object.keys(this.categories).length,
      totalTutorials: allTutorials.length,
      languages: Object.entries(languages)
        .sort((a, b) => b[1] - a[1])
        .map(([lang, count]) => ({ language: lang, count }))
    };
  }

  /**
   * Format tutorial for display
   */
  formatTutorial(tutorial) {
    return `${tutorial.category} | ${tutorial.language}\n  ${tutorial.title}\n  ${tutorial.url}`;
  }

  /**
   * Format results for display
   */
  formatResults(results) {
    if (results.length === 0) return 'No tutorials found.';
    return results.map(t => this.formatTutorial(t)).join('\n\n');
  }
}

module.exports = BuildYourOwnXIndex;
