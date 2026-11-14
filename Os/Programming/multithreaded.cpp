#include <iostream>
#include <thread>
#include <chrono>
#include <cmath>

using namespace std;
void task1()
{
    long long sum = 0;
    for (int i = 1; i <= 200000000; i++)
        sum += i;

    cout << "Task 1 completed. Sum = " << sum << "\n";
}
void task2()
{
    long long count = 0;
    for (int i = 1; i <= 20000000; i++)
        if (i % 7 == 0)
            count++;

    cout << "Task 2 completed. Numbers divisible by 7 = " << count << "\n";
}

void task3()
{
    long long fact = 1;

    cout << "Task 3 results:";
    for (int i = 1; i <= 15; i++)
    {
        fact *= i;   
    }
    cout << "  Factorial of " << fact << "\n";
}

void task4()
{
    double x = 0;
    for (int i = 1; i <= 50000000; i++)
        x += sin(i) * tan(i);

    cout << "Task 4 completed. Final value of x = " << x << "\n";
}

int main()
{
    cout << "Multithreaded Execution\n";

    auto start = chrono::high_resolution_clock::now();

    thread t1(task1);
    thread t2(task2);
    thread t3(task3);
    thread t4(task4);
    t1.join();
    t2.join();
    t3.join();
    t4.join();
    auto end = chrono::high_resolution_clock::now();
    chrono::duration<double> duration = end - start;

    cout << "\nTotal Execution Time (Multithreaded): "
         << duration.count() << " seconds\n";

    return 0;
}
