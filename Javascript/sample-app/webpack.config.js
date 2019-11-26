const path = require('path');

module.exports = {
  entry: './register.ts',
  devtool: "source-map",
   target: "web",
  module:{
      rules: [
          {
              test: /\.ts$/,
              use: 'ts-loader',
              exclude: /node_modules/,
          }
      ]
  },
  resolve: {
      extensions: ['.ts', '.js']
  },
  output: {
    path: path.join(__dirname, '/dist'),
    filename: 'bundle.js',
    library: 'bundle',
    libraryTarget: 'umd',
    globalObject: 'this'
  },
  devServer: {
      inline: false
  }
};
