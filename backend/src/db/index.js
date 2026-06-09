const { exec } = require('child_process');

const query = (sql) => {
  return new Promise((resolve, reject) => {
    // Escape single quotes for the shell command: ' -> '\''
    const escapedSql = sql.replace(/'/g, "'\\''");
    exec(`team-db '${escapedSql}'`, (error, stdout, stderr) => {
      if (error) {
        // console.error(`Error executing team-db: ${error.message}`);
        return reject(new Error(stdout || error.message));
      }
      
      const trimmedStdout = stdout.trim();
      if (trimmedStdout === '' || trimmedStdout === '[]') {
        return resolve([]);
      }

      try {
        const result = JSON.parse(trimmedStdout);
        resolve(result);
      } catch (e) {
        // If it's not JSON but not empty, it's likely an error message from team-db that didn't exit with non-zero
        // or a success message that we didn't expect.
        if (trimmedStdout.toLowerCase().includes('error')) {
          reject(new Error(trimmedStdout));
        } else {
          resolve(trimmedStdout);
        }
      }
    });
  });
};

module.exports = { query };
