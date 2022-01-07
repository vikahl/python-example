"""Example cli file defining two methods.

For more information about typer, read the excellent documentation at
https://typer.tiangolo.com/
"""
from typing import List

import typer

import python_project_example.lib

app = typer.Typer()


@app.command()
def add(number: List[float] = typer.Option([])) -> None:
    """Add numbers and print the sum."""

    typer.echo("Adding numbers")
    result = python_project_example.lib.add(*number)
    typer.echo(f"Result: {result}")


@app.command()
def hello(who: str) -> None:
    """Say hello to someone."""

    typer.echo(f"Hello {who}")
