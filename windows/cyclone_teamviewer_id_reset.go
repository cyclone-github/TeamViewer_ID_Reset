package main

import (
	"fmt"
	"os"
	"os/exec"
	"os/user"
	"path/filepath"
	"syscall"
	"time"
)

// kill TeamView process
func killTeamViewer() error {
	cmd := exec.Command("taskkill", "/F", "/IM", "TeamViewer.exe")
	err := cmd.Run()
	if err != nil {
		return fmt.Errorf("Error killing TeamViewer process: %s", err)
		time.Sleep(1000 * time.Millisecond)
	}
	return nil
}

// stop TeamViewer service
func stopTeamViewerService() error {
	cmd := exec.Command("net", "stop", "TeamViewer")
	err := cmd.Run()
	if err != nil {
		return fmt.Errorf("Error stopping TeamViewer service: %s", err)
		time.Sleep(1000 * time.Millisecond)
	}
	return nil
}

// remove TeamViewer registry keys
func removeTeamViewerRegistry() error {
	// Windows x64 - delete "HKLM\SOFTWARE\TeamViewer\"
	out64, err := exec.Command("reg", "delete", "HKEY_CURRENT_USER\\SOFTWARE\\Wow6432Node\\TeamViewer", "/f").CombinedOutput()
	if err != nil {
		return fmt.Errorf("Error deleting registry key: %s: %s", err, out64)
		time.Sleep(1000 * time.Millisecond)
	}

	// Windows x86 - delete "HKLM\SOFTWARE\TeamViewer\"
	out32, err := exec.Command("reg", "delete", "HKEY_CURRENT_USER\\SOFTWARE\\TeamViewer", "/f").CombinedOutput()
	if err != nil {
		return fmt.Errorf("Error deleting registry key: %s: %s", err, out32)
		time.Sleep(1000 * time.Millisecond)
	}

	return nil
}

func removeTeamViewerDir() error {
	usr, err := user.Current()
	if err != nil {
		return err
	}

	teamViewerDirRoaming := filepath.Join(usr.HomeDir, "AppData", "Roaming", "TeamViewer")
	err = os.RemoveAll(teamViewerDirRoaming)
	if err != nil {
		return err
	}

	teamViewerDirLocal := filepath.Join(usr.HomeDir, "AppData", "Local", "TeamViewer")
	err = os.RemoveAll(teamViewerDirLocal)
	if err != nil {
		return err
	}

	return nil
}

// reset "Program Files" create date
func setCreateTime(dir string, createTime time.Time) error {
	// Convert the create time to a syscall.Filetime
	ft := syscall.NsecToFiletime(createTime.UnixNano())

	// Open the directory
	handle, err := syscall.CreateFile(syscall.StringToUTF16Ptr(dir), syscall.GENERIC_READ|syscall.GENERIC_WRITE, syscall.FILE_SHARE_READ|syscall.FILE_SHARE_WRITE|syscall.FILE_SHARE_DELETE, nil, syscall.OPEN_EXISTING, syscall.FILE_FLAG_BACKUP_SEMANTICS, 0)
	if err != nil {
		return fmt.Errorf("Error opening directory: %s", err)
	}
	defer syscall.CloseHandle(handle)

	// Set the create time
	err = syscall.SetFileTime(handle, &syscall.Filetime{}, &syscall.Filetime{}, &ft)
	if err != nil {
		return fmt.Errorf("Error setting create time: %s", err)
	}
	return nil
}

func main() {
	// stop TeamViewer service
	stopService := stopTeamViewerService()
	if stopService != nil {
		fmt.Println(stopService)
		time.Sleep(1000 * time.Millisecond)
	} else {
		fmt.Println("TeamViewer service stopped successfully")
		time.Sleep(1000 * time.Millisecond)
	}

	// kill TeamViewer process
	killProc := killTeamViewer()
	if killProc != nil {
		fmt.Println(killProc)
	} else {
		fmt.Println("TeamViewer process killed successfully")
		time.Sleep(1000 * time.Millisecond)
	}

	//remove TeamViewer registry keys
	rmReg := removeTeamViewerRegistry()
	if rmReg != nil {
		fmt.Printf("Error removing registry key: %s\n", rmReg)
	} else {
		fmt.Println("Registry keys removed successfully")
		time.Sleep(1000 * time.Millisecond)
	}

	// remove TeamViewer directories
	rmDir := removeTeamViewerDir()
	if rmDir != nil {
		fmt.Printf("Error removing directory: %s\n", rmDir)
	} else {
		fmt.Println("Directories removed successfully")
		time.Sleep(1000 * time.Millisecond)
	}

	// reset Program Files creation date
	createTime := time.Date(2022, time.July, 15, 14, 25, 0, 0, time.UTC)
	errCreate := setCreateTime("C:\\Program Files", createTime)
	if errCreate != nil {
		fmt.Println(errCreate)
	} else {
		fmt.Println("Create time set successfully")
	}

	fmt.Println("Successfully reset TeamViewer ID")
	time.Sleep(5000 * time.Millisecond)
}
