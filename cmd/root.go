package cmd

import (
	"fmt"
	"os"

	"github.com/mitchellh/go-homedir"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

var cfgFile string

var rootCmd = newRootCmd()

func newRootCmd() *cobra.Command {
	return &cobra.Command{
		Use:	"ghux",
		Short:	"lets enjoy ghq and tmux",
		Long:	"This command is open ghq project eazy",
		RunE: func(cmd *cobra.Command, args []string) error {
			fmt.Println("bra")
			return nil
		},
	}
}


// Execute adds all child commands to the root command and sets flags appropriately.
// This is called by main.main(). It only needs to happen once to the rootCmd.
func Execute() {
	cmd := newRootCmd()
	cmd.SetOutput(os.Stdout)
	if err := rootCmd.Execute(); err != nil {
		cmd.SetOutput(os.Stderr)
		cmd.Println(err)
		os.Exit(1)
	}
}

func init() {
	rootCmd.PersistentFlags().StringVar(&cfgFile, "config", "", "config file (default is $HOME/.ghux.yaml)")

	rootCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
}

// initConfig reads in config file and ENV variables if set.
func initConfig() {
	if cfgFile != "" {
		// Use config file from the flag.
		viper.SetConfigFile(cfgFile)
	} else {
		// Find home directory.
		home, err := homedir.Dir()
		if err != nil {
			fmt.Println(err)
			os.Exit(1)
		}

		// Search config in home directory with name ".ghux" (without extension).
		viper.AddConfigPath(home)
		viper.SetConfigName(".ghux")
	}

	viper.AutomaticEnv() // read in environment variables that match

	// If a config file is found, read it in.
	if err := viper.ReadInConfig(); err == nil {
		fmt.Println("Using config file:", viper.ConfigFileUsed())
	}
}
