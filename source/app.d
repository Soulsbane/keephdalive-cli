import std.stdio;
import std.file;
import std.string;
import std.path;
import std.datetime;
import std.algorithm;

import ctoptions;
import dapplicationbase;
import dfileutils;
import keephdaliveapi;

import client;

struct Options
{
	@GetOptOptions("How many minutes to wait in between each write.")
	size_t delay = DEFAULT_FILE_WRITE_DELAY;
	@GetOptOptions("Name of the file to write to.")
	string filename = DEFAULT_WRITE_TO_FILENAME;
	@DisableSave @GetOptOptions("Add a path to the list of paths to be written to.", "ap", "add-path")
	string path;
}

class KeepAliveApp : Application!Options
{
public:
	this()
	{
		client_ = new KeepAliveClient;
	}

	bool addPath(const string path, const Flag!"shouldWrite" shouldWrite = Yes.shouldWrite)
	{
		return true;
	}

	override void onNoArguments()
	{
		saveOptions();
	}

	override void onValidArguments()
	{
		if(options_.hasPath())
		{
			immutable bool added = addPath(options_.getPath());

			if(added)
			{
				writeln("Added path: ", options_.getPath());
				onNoArguments();
			}
			else
			{
				writeln("Error: That path does not exist!");
			}
		}
		else
		{
			onNoArguments();
		}
	}

private:
	string writeToFileName_ = DEFAULT_WRITE_TO_FILENAME;
	long fileWriteDelay_ = DEFAULT_FILE_WRITE_DELAY;
	string[] locations_;
	KeepAliveSettings settings_;
	KeepAliveClient client_;
}

void main(string[] arguments)
{
	auto app = new KeepAliveApp;
	app.create("Raijinsoft", "keephdalive", arguments);
}
