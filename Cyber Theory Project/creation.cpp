#include <iostream>
#include <vector>

using namespace std;

struct Process
{
    int pid;
    int burstTime;
    int waitingTime;
    int turnAroundTime;
};

void calculateWaitingTime(vector<Process> &processes)
{
    processes[0].waitingTime = 0;

    for (size_t i = 1; i < processes.size(); i++)
    {
        processes[i].waitingTime = processes[i - 1].waitingTime + processes[i - 1].burstTime;
    }
}

void calculateTurnAroundTime(vector<Process> &processes)
{
    for (size_t i = 0; i < processes.size(); i++)
    {
        processes[i].turnAroundTime = processes[i].burstTime + processes[i].waitingTime;
    }
}

void calculateAverageTimes(const vector<Process> &processes)
{
    int totalWaitingTime = 0;
    int totalTurnAroundTime = 0;

    for (const auto &process : processes)
    {
        totalWaitingTime += process.waitingTime;
        totalTurnAroundTime += process.turnAroundTime;
    }

    cout << "Average Waiting Time: " << (float)totalWaitingTime / processes.size() << endl;
    cout << "Average Turnaround Time: " << (float)totalTurnAroundTime / processes.size() << endl;
}

void displayProcessDetails(const vector<Process> &processes)
{
    cout << "\nProcess\tBurst Time\tWaiting Time\tTurnaround Time\n";
    for (const auto &process : processes)
    {
        cout << process.pid << "\t" << process.burstTime << "\t\t"
             << process.waitingTime << "\t\t" << process.turnAroundTime << endl;
    }
}

int main()
{
    int n;

    cout << "Enter the number of processes: ";
    cin >> n;

    vector<Process> processes(n);

    for (int i = 0; i < n; i++)
    {
        processes[i].pid = i + 1;
        cout << "Enter burst time for process " << processes[i].pid << ": ";
        cin >> processes[i].burstTime;
    }

    calculateWaitingTime(processes);

    calculateTurnAroundTime(processes);

    displayProcessDetails(processes);

    calculateAverageTimes(processes);

    return 0;
}