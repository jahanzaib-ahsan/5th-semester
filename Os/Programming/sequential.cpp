#include <iostream>
#include <chrono>
#include <cmath>
using namespace std;

void task1()
{
    long long sum = 0;
    for (int i = 1; i <= 200000000; i++)
        sum += i;

    cout << "Task 1 completed ( sum = " << sum << " )\n";
}

void task2()
{
    long long count = 0;
    for (int i = 1; i <= 20000000; i++)
        if (i % 7 == 0)
            count++;

    cout << "Task 2 completed ( count = " << count << " )\n";
}

void task3()
{
    long long fact = 1;
    for (int i = 1; i <= 15; i++)
        fact *= i;

    cout << "Task 3 completed (Factorials = " << fact << " )\n";
}

void task4()
{
    double x = 0;
    for (int i = 1; i <= 50000000; i++)
        x += sin(i) * tan(i);

    cout << "Task 4 completed ( x = " << x << " )\n";
}

int main()
{
    cout << "Sequential Execution\n";
    auto start = chrono::high_resolution_clock::now();

    task1();
    task2();
    task3();
    task4();

    auto end = chrono::high_resolution_clock::now();
    chrono::duration<double> duration = end - start;

    cout << "Total Execution Time (Sequential): "
         << duration.count() << " seconds\n";

    return 0;
}
